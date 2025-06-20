class Company < ApplicationRecord
  # Associations
  has_many :users, dependent: :nullify
  has_many :teams, dependent: :nullify
  has_many :events, dependent: :nullify
  has_many :api_keys, dependent: :nullify
  has_many :audit_logs, dependent: :nullify
  has_many :alerts, dependent: :nullify
  has_many :invitations, dependent: :nullify
  has_many :activities, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :domain, uniqueness: true, allow_blank: true
  validates :is_active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :ordered, -> { order(:name) }

  # Instance methods
  def user_count
    users.count
  end

  def team_count
    teams.count
  end

  def event_count
    events.count
  end

  def alert_count
    alerts.count
  end

  def api_key_count
    api_keys.count
  end

  def audit_log_count
    audit_logs.count
  end

  def analytics_summary
    {
      users: user_count,
      teams: team_count,
      events: event_count,
      alerts: alert_count,
      api_keys: api_key_count,
      audit_logs: audit_log_count
    }
  end

  def last_activity
    [
      users.maximum(:last_login_at),
      events.maximum(:created_at),
      audit_logs.maximum(:created_at)
    ].compact.max
  end
end 