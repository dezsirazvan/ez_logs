class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable, :lockable, :timeoutable

  # Associations
  belongs_to :company
  belongs_to :role
  belongs_to :team, optional: true
  has_many :user_sessions, dependent: :destroy
  has_many :invitations, foreign_key: :invited_by_id, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :owned_teams, class_name: "Team", foreign_key: :owner_id, dependent: :nullify

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :role, presence: true
  validates :login_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :failed_login_attempts, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :timezone, presence: true
  validates :language, presence: true
  validates :company, presence: true

  # MFA and security fields
  validates :mfa_enabled, inclusion: { in: [true, false] }
  validates :backup_codes, presence: true, if: :mfa_enabled?

  # Notification preferences
  validates :email_notifications, inclusion: { in: [true, false] }
  validates :alert_notifications, inclusion: { in: [true, false] }
  validates :team_notifications, inclusion: { in: [true, false] }
  validates :company_notifications, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :set_default_role, on: :create
  before_create :generate_two_factor_secret
  before_create :generate_backup_codes
  after_create :create_default_team
  after_update :log_profile_changes

  # Scopes
  scope :active, -> { where(locked_at: nil) }
  scope :locked, -> { where.not(locked_at: nil) }
  scope :with_mfa, -> { where(mfa_enabled: true) }
  scope :without_mfa, -> { where(mfa_enabled: false) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :by_team, ->(team) { where(team: team) }
  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }

  # Virtual attributes for 2FA
  attr_accessor :two_factor_code, :backup_code

  # Default values
  attribute :mfa_enabled, :boolean, default: false
  attribute :email_notifications, :boolean, default: true
  attribute :alert_notifications, :boolean, default: true
  attribute :team_notifications, :boolean, default: true
  attribute :company_notifications, :boolean, default: true
  attribute :timezone, :string, default: 'UTC'
  attribute :language, :string, default: 'en'

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.presence || email
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
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

  def confirmed_at?
    confirmed_at.present?
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
    return false unless mfa_enabled?
    return false unless backup_codes.is_a?(Array)
    
    normalized_code = code.to_s.upcase.strip
    backup_codes.include?(normalized_code)
  end

  def consume_backup_code(code)
    return false unless verify_backup_code(code)
    
    normalized_code = code.to_s.upcase.strip
    remaining_codes = backup_codes.reject { |c| c == normalized_code }
    update!(backup_codes: remaining_codes)
    
    # Log the activity
    Activity.log_backup_codes_regenerated(self)
    
    true
  end

  def generate_new_backup_codes
    codes = Array.new(10) { SecureRandom.hex(4).upcase }
    update!(backup_codes: codes)
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
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
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
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      details: { reason: "admin_action" }
    )
  rescue => e
    Rails.logger.error "Failed to log account unlock: #{e.message}"
  end

  def enable_mfa!
    return true if mfa_enabled?

    # Ensure company_notifications has a valid value
    self.company_notifications = true if company_notifications.nil?

    update!(
      mfa_enabled: true,
      backup_codes: generate_new_backup_codes,
      company_notifications: company_notifications
    )

    AuditLog.create!(
      user: self,
      action: "mfa_enabled",
      resource_type: "User",
      resource_id: id,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      details: { method: "totp" }
    )
  rescue => e
    Rails.logger.error "Failed to log MFA enable: #{e.message}"
  end

  def disable_mfa!
    return true unless mfa_enabled?

    update!(
      mfa_enabled: false,
      backup_codes: nil,
      two_factor_secret: nil
    )

    AuditLog.create!(
      user: self,
      action: "mfa_disabled",
      resource_type: "User",
      resource_id: id,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      details: { method: "totp" }
    )
  rescue => e
    Rails.logger.error "Failed to log MFA disable: #{e.message}"
  end

  def team_owner?
    team&.owner == self
  end

  def team_admin?
    role.name == 'admin' || team_owner?
  end

  def can_manage_team?
    team_admin? || role.name == 'manager'
  end

  def can_invite_members?
    can_manage_team?
  end

  def can_remove_members?
    can_manage_team?
  end

  def can_change_roles?
    can_manage_team?
  end

  def can_transfer_ownership?
    team_owner?
  end

  def can_view_team_activity?
    team.present?
  end

  def can_view_user_activity?(other_user)
    return true if self == other_user
    return true if admin?
    return true if team_admin? && other_user.team == team
    false
  end

  def recent_activity(limit: 10)
    activities.recent.limit(limit)
  end

  def activity_summary
    {
      total_events: company.events.count,
      events_this_month: company.events.where(created_at: 1.month.ago..Time.current).count,
      total_alerts: company.alerts.count,
      active_api_keys: company.api_keys.where(is_active: true).count
    }
  end

  def api_key_summary
    {
      total_keys: company.api_keys.count,
      active_keys: company.api_keys.where(is_active: true).count,
      expired_keys: company.api_keys.where('expires_at < ?', Time.current).count
    }
  end

  def team_summary
    return nil unless team

    {
      name: team.name,
      member_count: team.member_count,
      active_members: team.active_member_count,
      pending_invitations: team.pending_invitations_count,
      is_owner: team_owner?,
      can_manage: can_manage_team?
    }
  end

  def notification_preferences
    {
      email_notifications: email_notifications,
      alert_notifications: alert_notifications,
      team_notifications: team_notifications
    }
  end

  def update_notification_preferences(preferences)
    update!(
      email_notifications: preferences[:email_notifications],
      alert_notifications: preferences[:alert_notifications],
      team_notifications: preferences[:team_notifications]
    )
  end

  def timezone_offset
    ActiveSupport::TimeZone[timezone]&.utc_offset || 0
  end

  def local_time(time = Time.current)
    time.in_time_zone(timezone)
  end

  def format_local_time(time, format = :long)
    local_time(time).strftime(format)
  end

  def update_tracked_fields!(request)
    super
  end

  def update_tracked_fields(request)
    super
  end

  def is_active?
    !!self[:is_active]
  end

  private

  def set_default_role
    self.role ||= Role.find_by(name: "viewer") || Role.first
  end

  def generate_two_factor_secret
    self.two_factor_secret = ROTP::Base32.random
  end

  def generate_backup_codes
    return unless mfa_enabled?
    self.backup_codes = Array.new(10) { SecureRandom.hex(4).upcase }
  end

  def create_default_team
    return if team.present?

    default_team = company.teams.first
    update(team: default_team) if default_team
  end

  def log_profile_changes
    return unless saved_changes.any?

    changes = saved_changes.except('updated_at', 'tracked_fields')
    return if changes.empty?

    AuditLog.create!(
      user: self,
      action: "profile_updated",
      resource_type: "User",
      resource_id: id,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      details: { changes: changes.keys }
    )
  rescue => e
    Rails.logger.error "Failed to log profile changes: #{e.message}"
  end
end
