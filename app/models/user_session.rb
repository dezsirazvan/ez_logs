class UserSession < ApplicationRecord
  belongs_to :user

  validates :started_at, presence: true

  scope :active, -> { where(ended_at: nil) }
  scope :ended, -> { where.not(ended_at: nil) }
  scope :recent, -> { order(started_at: :desc) }

  def active?
    ended_at.nil?
  end

  def ended?
    ended_at.present?
  end

  def end_session!
    update(ended_at: Time.current)
  end

  def duration
    return nil unless ended_at
    (ended_at - started_at).to_i
  end
end
