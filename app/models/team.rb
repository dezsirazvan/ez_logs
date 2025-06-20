class Team < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :owner, class_name: "User"
  has_many :users, dependent: :nullify
  has_many :invitations, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :alerts, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, presence: true, length: { maximum: 500 }
  validates :is_active, inclusion: { in: [ true, false ] }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :ordered, -> { order(:name) }
  scope :owned_by, ->(user) { where(owner: user) }

  # Callbacks
  before_validation :set_default_settings
  after_create :log_team_creation
  after_update :log_team_update
  after_destroy :log_team_deletion

  # Instance methods
  def member_count
    users.count
  end

  def active_member_count
    users.active.count
  end

  def pending_invitations_count
    invitations.pending.count
  end

  def owner?(user)
    owner_id == user.id
  end

  def member?(user)
    users.include?(user)
  end

  def can_manage?(user)
    owner?(user) || user.admin?
  end

  def can_invite?(user)
    can_manage?(user) || user.can_access?("teams", "manage_members")
  end

  def add_member(user, role = nil)
    return false if member?(user)

    user.update(team: self, role: role) if role

    AuditLog.create!(
      user: Current.user || owner,
      action: "member_added",
      resource_type: "Team",
      resource_id: id,
      details: {
        member_id: user.id,
        member_email: user.email,
        role: role&.name
      }
    )

    true
  rescue => e
    Rails.logger.error "Failed to log member addition: #{e.message}"
    true
  end

  def remove_member(user)
    return false unless member?(user)

    user.update(team: nil)

    AuditLog.create!(
      user: Current.user || owner,
      action: "member_removed",
      resource_type: "Team",
      resource_id: id,
      details: {
        member_id: user.id,
        member_email: user.email
      }
    )

    true
  rescue => e
    Rails.logger.error "Failed to log member removal: #{e.message}"
    true
  end

  def invite_user(email, role, invited_by)
    return false if users.exists?(email: email)

    invitation = invitations.create!(
      email: email,
      role: role,
      invited_by: invited_by,
      token: SecureRandom.hex(32),
      expires_at: 7.days.from_now
    )

    AuditLog.create!(
      user: invited_by,
      action: "invitation_sent",
      resource_type: "Team",
      resource_id: id,
      details: {
        email: email,
        role: role.name,
        invitation_id: invitation.id
      }
    )

    # Send invitation email (background job)
    InvitationMailer.invitation_email(invitation).deliver_later

    invitation
  rescue => e
    Rails.logger.error "Failed to log invitation: #{e.message}"
    invitation
  end

  def accept_invitation(token, user)
    invitation = invitations.pending.find_by(token: token)
    return false unless invitation
    return false if invitation.expires_at < Time.current

    invitation.update(status: "accepted")
    add_member(user, invitation.role)

    AuditLog.create!(
      user: user,
      action: "invitation_accepted",
      resource_type: "Team",
      resource_id: id,
      details: {
        invitation_id: invitation.id,
        role: invitation.role.name
      }
    )

    true
  rescue => e
    Rails.logger.error "Failed to log invitation acceptance: #{e.message}"
    true
  end

  def decline_invitation(token)
    invitation = invitations.pending.find_by(token: token)
    return false unless invitation

    invitation.update(status: "declined")

    AuditLog.create!(
      user: Current.user || owner,
      action: "invitation_declined",
      resource_type: "Team",
      resource_id: id,
      details: {
        invitation_id: invitation.id
      }
    )

    true
  rescue => e
    Rails.logger.error "Failed to log invitation decline: #{e.message}"
    true
  end

  def transfer_ownership(new_owner)
    return false unless member?(new_owner)
    return false if owner?(new_owner)

    old_owner = owner
    update(owner: new_owner)

    AuditLog.create!(
      user: old_owner,
      action: "ownership_transferred",
      resource_type: "Team",
      resource_id: id,
      details: {
        new_owner_id: new_owner.id,
        new_owner_email: new_owner.email
      }
    )

    true
  rescue => e
    Rails.logger.error "Failed to log ownership transfer: #{e.message}"
    true
  end

  def deactivate!
    update(is_active: false)

    AuditLog.create!(
      user: Current.user || owner,
      action: "team_deactivated",
      resource_type: "Team",
      resource_id: id,
      details: { reason: "admin_action" }
    )
  rescue => e
    Rails.logger.error "Failed to log team deactivation: #{e.message}"
  end

  def activate!
    update(is_active: true)

    AuditLog.create!(
      user: Current.user || owner,
      action: "team_activated",
      resource_type: "Team",
      resource_id: id,
      details: { reason: "admin_action" }
    )
  rescue => e
    Rails.logger.error "Failed to log team activation: #{e.message}"
  end

  def update_settings(new_settings)
    current_settings = settings.is_a?(Hash) ? settings : {}
    updated_settings = current_settings.merge(new_settings.stringify_keys)

    update(settings: updated_settings)

    AuditLog.create!(
      user: Current.user || owner,
      action: "settings_updated",
      resource_type: "Team",
      resource_id: id,
      details: { changes: new_settings }
    )
  rescue => e
    Rails.logger.error "Failed to log settings update: #{e.message}"
  end

  def get_setting(key, default = nil)
    return default unless settings.is_a?(Hash)
    settings[key.to_s] || default
  end

  def analytics_summary
    {
      member_count: member_count,
      active_member_count: active_member_count,
      pending_invitations: pending_invitations_count,
      events_count: events.count,
      alerts_count: alerts.count,
      created_at: created_at,
      last_activity: last_activity
    }
  end

  def last_activity
    [
      users.maximum(:last_login_at),
      events.maximum(:created_at),
      audit_logs.maximum(:created_at)
    ].compact.max
  end

  def can_be_deleted?
    users.count == 0 && events.count == 0 && alerts.count == 0
  end

  def soft_delete!
    return false unless can_be_deleted?

    update(is_active: false)
  end

  def display_name
    "#{name} (#{member_count} members)"
  end

  def to_s
    name
  end

  private

  def set_default_settings
    return if settings.present?

    self.settings = {
      "allow_member_invitations" => true,
      "require_approval_for_events" => false,
      "auto_archive_old_events" => true,
      "archive_after_days" => 90,
      "max_members" => 50,
      "notification_preferences" => {
        "email" => true,
        "slack" => false,
        "webhook" => false
      }
    }
  end

  def log_team_creation
    AuditLog.create!(
      user: Current.user || owner,
      action: "team_created",
      resource_type: "Team",
      resource_id: id,
      details: {
        team_name: name,
        team_description: description,
        owner_email: owner.email,
        member_count: 1
      }
    )
  rescue => e
    Rails.logger.error "Failed to log team creation: #{e.message}"
  end

  def log_team_update
    return unless saved_changes.any?

    AuditLog.create!(
      user: Current.user || owner,
      action: "team_updated",
      resource_type: "Team",
      resource_id: id,
      details: {
        team_name: name,
        changes: saved_changes.except("updated_at"),
        previous_changes: saved_changes_was
      }
    )
  rescue => e
    Rails.logger.error "Failed to log team update: #{e.message}"
  end

  def log_team_deletion
    AuditLog.create!(
      user: Current.user || owner,
      action: "team_deleted",
      resource_type: "Team",
      resource_id: id,
      details: {
        team_name: name,
        member_count: users.count,
        owner_email: owner.email
      }
    )
  rescue => e
    Rails.logger.error "Failed to log team deletion: #{e.message}"
  end
end
