class Alert < ApplicationRecord
  belongs_to :company

  validates :name, presence: true
  validates :is_active, inclusion: { in: [true, false] }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_team, ->(team) { where(team: team) }
  scope :active, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }

  def active?
    resolved_at.nil?
  end

  def resolved?
    resolved_at.present?
  end

  def resolve!
    update(resolved_at: Time.current)
  end

  def display_name
    name
  end

  def title
    name
  end
end
