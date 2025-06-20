class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :github ]

  # Associations
  belongs_to :role
  belongs_to :team
  has_many :audit_logs, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :invitations_sent, class_name: "Invitation", foreign_key: "invited_by", dependent: :destroy
  has_many :owned_teams, class_name: "Team", foreign_key: "owner_id", dependent: :destroy

  # Validations
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :login_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :failed_login_attempts, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks
  before_create :set_default_role
  before_create :generate_two_factor_secret
  before_create :generate_backup_codes
  after_create :create_default_team
  after_update :log_profile_changes

  # Scopes
  scope :active, -> { where(locked_at: nil) }
  scope :locked, -> { where.not(locked_at: nil) }
  scope :with_mfa, -> { where(mfa_enabled: true) }
  scope :recent_login, -> { where("last_login_at > ?", 7.days.ago) }

  # Virtual attributes for 2FA
  attr_accessor :two_factor_code, :backup_code

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.presence || email
  end

  def admin?
    role.name == "admin"
  end

  def developer?
    role.name == "developer"
  end

  def viewer?
    role.name == "viewer"
  end

  def read_only?
    role.name == "read_only"
  end

  def locked?
    locked_at.present?
  end

  def mfa_enabled?
    mfa_enabled == true
  end

  def can_access?(resource, action = nil)
    return true if admin?

    permissions = role.permissions || {}
    resource_permissions = permissions[resource.to_s] || {}

    if action
      resource_permissions[action.to_s] == true
    else
      resource_permissions.values.any?
    end
  end

  def require_mfa?
    admin? || developer? || mfa_enabled?
  end

  def verify_two_factor_code(code)
    return false unless mfa_enabled?

    totp = ROTP::TOTP.new(two_factor_secret)
    totp.verify(code, drift_behind: 30, drift_ahead: 30)
  end

  def verify_backup_code(code)
    return false unless two_factor_backup_codes.present?

    codes = JSON.parse(two_factor_backup_codes)
    if codes.include?(code)
      codes.delete(code)
      update(two_factor_backup_codes: codes.to_json)
      true
    else
      false
    end
  end

  def generate_new_backup_codes
    codes = 8.times.map { SecureRandom.hex(4).upcase }
    update(two_factor_backup_codes: codes.to_json)
    codes
  end

  def qr_code_data
    return nil unless two_factor_secret.present?

    totp = ROTP::TOTP.new(two_factor_secret)
    totp.provisioning_uri(email, issuer: "EZLogs")
  end

  def record_login(ip_address = nil)
    update(
      last_login_at: Time.current,
      login_count: (login_count || 0) + 1,
      failed_login_attempts: 0
    )

    user_sessions.create!(
      ip_address: ip_address,
      user_agent: Current.user_agent,
      started_at: Time.current
    )

    AuditLog.create!(
      user: self,
      action: "login",
      resource_type: "User",
      resource_id: id,
      ip_address: ip_address,
      user_agent: Current.user_agent,
      details: { success: true }
    )
  rescue => e
    Rails.logger.error "Failed to log login: #{e.message}"
  end

  def record_failed_login(ip_address = nil)
    update(failed_login_attempts: (failed_login_attempts || 0) + 1)

    AuditLog.create!(
      user: self,
      action: "login_failed",
      resource_type: "User",
      resource_id: id,
      ip_address: ip_address,
      user_agent: Current.user_agent,
      details: { reason: "invalid_credentials" }
    )
  rescue => e
    Rails.logger.error "Failed to log failed login: #{e.message}"
  end

  def lock_account!
    update(locked_at: Time.current)

    AuditLog.create!(
      user: self,
      action: "account_locked",
      resource_type: "User",
      resource_id: id,
      details: { reason: "too_many_failed_attempts" }
    )
  rescue => e
    Rails.logger.error "Failed to log account lock: #{e.message}"
  end

  def unlock_account!
    update(locked_at: nil, failed_login_attempts: 0)

    AuditLog.create!(
      user: self,
      action: "account_unlocked",
      resource_type: "User",
      resource_id: id,
      details: { reason: "admin_action" }
    )
  rescue => e
    Rails.logger.error "Failed to log account unlock: #{e.message}"
  end

  def enable_mfa!
    update(mfa_enabled: true)

    AuditLog.create!(
      user: self,
      action: "mfa_enabled",
      resource_type: "User",
      resource_id: id,
      details: { method: "totp" }
    )
  rescue => e
    Rails.logger.error "Failed to log MFA enable: #{e.message}"
  end

  def disable_mfa!
    update(
      mfa_enabled: false,
      two_factor_secret: nil,
      two_factor_backup_codes: nil
    )

    AuditLog.create!(
      user: self,
      action: "mfa_disabled",
      resource_type: "User",
      resource_id: id,
      details: { method: "totp" }
    )
  rescue => e
    Rails.logger.error "Failed to log MFA disable: #{e.message}"
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.first_name = auth.info.first_name || auth.info.name.split.first
      user.last_name = auth.info.last_name || auth.info.name.split.last
      user.password = Devise.friendly_token[0, 20]
      user.confirmed_at = Time.current # Skip email confirmation for OAuth
    end
  end

  private

  def set_default_role
    self.role ||= Role.find_by(name: "viewer") || Role.first
  end

  def generate_two_factor_secret
    self.two_factor_secret = ROTP::Base32.random
  end

  def generate_backup_codes
    self.two_factor_backup_codes = 8.times.map { SecureRandom.hex(4).upcase }.to_json
  end

  def create_default_team
    return if team.present?

    default_team = Team.create!(
      name: "#{full_name}'s Team",
      description: "Default team for #{full_name}",
      owner: self,
      user: self
    )

    update(team: default_team)
  end

  def log_profile_changes
    return unless saved_changes.any?

    changes = saved_changes.except("updated_at", "login_count", "last_login_at")
    return if changes.empty?

    AuditLog.create!(
      user: self,
      action: "profile_updated",
      resource_type: "User",
      resource_id: id,
      details: { changes: changes }
    )
  rescue => e
    Rails.logger.error "Failed to log profile changes: #{e.message}"
  end
end
