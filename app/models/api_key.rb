class ApiKey < ApplicationRecord
  belongs_to :company

  validates :token, presence: true, uniqueness: true
  validates :is_active, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_default_permissions, on: :create

  scope :active, -> { where(revoked_at: nil) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # Default permissions
  DEFAULT_PERMISSIONS = {
    'events' => ['read', 'create'],
    'alerts' => ['read'],
    'analytics' => ['read']
  }.freeze

  # Permission types
  PERMISSION_TYPES = %w[read write create update delete].freeze

  # Resource types
  RESOURCE_TYPES = %w[events alerts analytics users teams].freeze

  def self.authenticate(token)
    active.find_by(token: token)
  end

  def self.generate_token
    SecureRandom.hex(32)
  end

  def active?
    revoked_at.nil?
  end

  def revoked?
    !active?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def regenerate!
    update!(
      token: self.class.generate_token,
      last_used_at: nil,
      revoked_at: nil
    )
  end

  def update_last_used!
    update!(last_used_at: Time.current)
  end

  def has_permission?(resource, action)
    return false unless active?
    return false unless permissions.present?

    resource_permissions = permissions[resource.to_s]
    return false unless resource_permissions

    resource_permissions.include?(action.to_s) || resource_permissions.include?('*')
  end

  def can_read?(resource)
    has_permission?(resource, 'read')
  end

  def can_write?(resource)
    has_permission?(resource, 'write')
  end

  def can_create?(resource)
    has_permission?(resource, 'create')
  end

  def can_update?(resource)
    has_permission?(resource, 'update')
  end

  def can_delete?(resource)
    has_permission?(resource, 'delete')
  end

  def can_manage?(resource)
    has_permission?(resource, 'manage')
  end

  def display_name
    name.presence || "API Key #{id}"
  end

  def masked_token
    return nil unless token
    "#{token[0..7]}...#{token[-8..-1]}"
  end

  def usage_summary
    {
      total_requests: request_count || 0,
      last_used: last_used_at,
      created: created_at,
      status: active? ? 'active' : 'revoked'
    }
  end

  private

  def generate_token
    self.token = self.class.generate_token if token.blank?
  end

  def set_default_permissions
    self.permissions = DEFAULT_PERMISSIONS if permissions.blank?
  end
end
