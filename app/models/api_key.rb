class ApiKey < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :key_hash, presence: true, uniqueness: true
  validates :permissions, presence: true

  before_validation :generate_key_hash, on: :create
  before_validation :set_default_permissions, on: :create

  scope :active, -> { where(expires_at: nil).or(where("expires_at > ?", Time.current)) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def self.generate_key
    SecureRandom.hex(32)
  end

  def key=(value)
    @key = value
    self.key_hash = Digest::SHA256.hexdigest(value) if value.present?
  end

  def key
    @key
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired?
  end

  def has_permission?(resource, action)
    return false unless permissions.is_a?(Hash)
    return false unless permissions[resource].is_a?(Array)
    permissions[resource].include?(action.to_s)
  end

  def can_read?(resource)
    has_permission?(resource, "read")
  end

  def can_create?(resource)
    has_permission?(resource, "create")
  end

  def can_update?(resource)
    has_permission?(resource, "update")
  end

  def can_delete?(resource)
    has_permission?(resource, "delete")
  end

  def mark_used!
    update(last_used_at: Time.current)
  end

  private

  def generate_key_hash
    return if key_hash.present?

    @key = self.class.generate_key
    self.key_hash = Digest::SHA256.hexdigest(@key)
  end

  def set_default_permissions
    return if permissions.present?

    self.permissions = {
      "events" => [ "read" ],
      "analytics" => [ "read" ]
    }
  end
end
