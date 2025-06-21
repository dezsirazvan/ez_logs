class Company < ApplicationRecord
  # Associations
  has_many :users, dependent: :nullify
  has_many :events, dependent: :nullify
  has_many :api_keys, dependent: :nullify
  has_many :alerts, dependent: :nullify
  has_many :invitations, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :domain, uniqueness: true, allow_blank: true
  validates :is_active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :ordered, -> { order(:name) }
  scope :recent, -> { order(created_at: :desc) }

  # Default values
  attribute :is_active, :boolean, default: true

  # Instance methods
  def display_name
    name.presence || domain.presence || "Company #{id}"
  end

  def active?
    is_active
  end

  def deactivate!
    update!(is_active: false)
  end

  def activate!
    update!(is_active: true)
  end

  def user_count
    users.count
  end

  def event_count
    events.count
  end

  def api_key_count
    api_keys.count
  end

  def alert_count
    alerts.count
  end

  def active_user_count
    users.active.count
  end

  def locked_user_count
    users.locked.count
  end
end 