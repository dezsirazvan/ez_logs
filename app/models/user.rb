class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable,
         :trackable

  # Associations
  belongs_to :company
  belongs_to :role
  has_many :api_keys, through: :company
  has_many :events, through: :company
  has_many :alerts, through: :company

  # Validations
  validates :email, presence: true, uniqueness: { scope: :company_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
  validates :timezone, presence: true
  validates :language, presence: true, inclusion: { in: %w[en es fr de it pt] }
  validates :role, presence: true

  # Callbacks
  before_validation :set_default_role, on: :create
  after_update :log_profile_changes

  # Scopes
  scope :active, -> { where(locked_at: nil) }
  scope :locked, -> { where.not(locked_at: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }

  # Virtual attributes
  attr_accessor :password_confirmation

  # Default values
  attribute :timezone, :string, default: 'UTC'
  attribute :language, :string, default: 'en'
  attribute :is_active, :boolean, default: true

  # Role methods
  def admin?
    role&.name == 'admin'
  end

  def user?
    role&.name == 'user'
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

  # Profile methods
  def display_name
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}"
    elsif first_name.present?
      first_name
    else
      email
    end
  end

  def initials
    if first_name.present? && last_name.present?
      "#{first_name[0]}#{last_name[0]}".upcase
    elsif first_name.present?
      first_name[0].upcase
    else
      email[0].upcase
    end
  end

  def full_name
    display_name
  end

  def avatar_url
    # You can integrate with services like Gravatar here
    "https://ui-avatars.com/api/?name=#{CGI.escape(display_name)}&background=random&color=fff&size=200"
  end

  # Activity methods
  def timezone_offset
    ActiveSupport::TimeZone[timezone]&.utc_offset || 0
  end

  # API Key methods
  def api_key_summary
    {
      total: company.api_keys.count,
      active: company.api_keys.where(is_active: true).count,
      inactive: company.api_keys.where(is_active: false).count,
      recent: company.api_keys.where('created_at >= ?', 7.days.ago).count
    }
  end

  # Authentication methods
  def confirmed?
    confirmed_at.present?
  end

  def locked?
    locked_at.present?
  end

  def active?
    is_active && !locked?
  end

  def lock!
    update!(locked_at: Time.current)
  end

  def unlock!
    update!(locked_at: nil)
  end

  def confirm!
    update!(confirmed_at: Time.current)
  end

  # Password methods
  def password_required?
    new_record? || password.present?
  end

  def authenticate(unencrypted_password)
    return false unless active?
    super(unencrypted_password)
  end

  # Notification preferences (simplified)
  def notification_preferences
    {
      email_notifications: true,
      alert_notifications: true
    }
  end

  private

  def set_default_role
    return if role.present?
    
    default_role = Role.find_by(name: 'user')
    self.role = default_role if default_role
  end

  def log_profile_changes
    # Log profile changes for audit purposes
    Rails.logger.info "User #{id} profile updated at #{Time.current}"
  end
end
