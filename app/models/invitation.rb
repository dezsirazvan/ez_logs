class Invitation < ApplicationRecord
  # Associations
  belongs_to :invited_by, class_name: "User"

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: %w[pending accepted declined expired] }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }
  scope :expired, -> { where(status: "expired") }
  scope :active, -> { pending.where("expires_at > ?", Time.current) }
  scope :expired_scope, -> { pending.where("expires_at <= ?", Time.current) }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create
  after_create :send_invitation_email
  after_update :log_status_change

  # Instance methods
  def expired?
    expires_at <= Time.current
  end

  def active?
    status == "pending" && !expired?
  end

  def can_be_accepted?
    active? && !user_exists?
  end

  def can_be_declined?
    active?
  end

  def user_exists?
    User.exists?(email: email)
  end

  def accept!(user)
    return false unless can_be_accepted?

    update(status: "accepted")

    true
  end

  def decline!
    return false unless can_be_declined?

    update(status: "declined")

    true
  end

  def expire!
    return false unless status == "pending"

    update(status: "expired")

    true
  end

  def resend!
    return false unless status == "pending"

    update(
      expires_at: 7.days.from_now,
      token: SecureRandom.urlsafe_base64(32)
    )

    send_invitation_email

    true
  end

  def days_until_expiry
    return 0 if expired?
    ((expires_at - Time.current) / 1.day).ceil
  end

  def status_color
    case status
    when "pending"
      expired? ? "red" : "yellow"
    when "accepted"
      "green"
    when "declined"
      "red"
    when "expired"
      "gray"
    end
  end

  def status_text
    case status
    when "pending"
      expired? ? "Expired" : "Pending"
    when "accepted"
      "Accepted"
    when "declined"
      "Declined"
    when "expired"
      "Expired"
    end
  end

  # Class methods
  def self.cleanup_expired
    expired_scope.find_each do |invitation|
      invitation.expire!
    end
  end

  def self.pending_for_email(email)
    active.where(email: email)
  end

  def self.accepted_by_user(user)
    accepted.where(email: user.email)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32) if token.blank?
  end

  def set_expires_at
    self.expires_at = 7.days.from_now if expires_at.blank?
  end

  def send_invitation_email
    InvitationMailer.invitation_email(self).deliver_later
  end

  def log_status_change
    return unless saved_change_to_status?

    # No audit_logs to create or log status change
  end
end
