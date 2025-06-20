class Team < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :owner, class_name: "User", optional: true
  has_many :users, dependent: :nullify
  has_many :invitations, dependent: :destroy
  has_many :events, through: :company
  has_many :alerts, through: :company

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :is_active, inclusion: { in: [true, false] }
  validates :company, presence: true

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :ordered, -> { order(:name) }
  scope :owned_by, ->(user) { where(owner: user) }
  scope :by_owner, ->(owner) { where(owner: owner) }
  scope :recent, -> { order(created_at: :desc) }

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
    users.where(locked_at: nil).count
  end

  def pending_invitations_count
    Invitation.where(team_id: id, status: 'pending').count
  end

  def owner?(user)
    owner_id == user.id
  end

  def member?(user)
    users.include?(user)
  end

  def can_manage?(user)
    return false unless user
    user.role.name == 'admin' || owner?(user)
  end

  def can_invite?(user)
    can_manage?(user)
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
    return false if owner?(user)
    return false unless users.include?(user)
    
    transaction do
      user.update!(team: nil, role: Role.find_by(name: 'member'))
      
      # Log the activity
      Activity.log_team_member_removed(owner, removed_user: user) if defined?(Activity)
    end
    
    true
  rescue => e
    Rails.logger.error "Failed to remove team member: #{e.message}"
    false
  end

  def invite_user(email, role, invited_by)
    return nil if users.exists?(email: email)
    return nil if invitations.where(status: 'pending').exists?(email: email)
    
    invitation = invitations.create!(
      email: email,
      role: role,
      invited_by: invited_by
    )
    
    # Log the activity
    Activity.log_team_invitation(invited_by, invited_email: email, role: role) if defined?(Activity)
    
    # Send invitation email
    TeamInvitationMailer.invitation(invitation).deliver_later if defined?(TeamInvitationMailer)
    
    invitation
  rescue => e
    Rails.logger.error "Failed to create team invitation: #{e.message}"
    nil
  end

  def accept_invitation(token, user)
    invitation = invitations.where(status: 'pending').find_by(token: token)
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
    invitation = invitations.where(status: 'pending').find_by(token: token)
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
    return false unless users.include?(new_owner)
    return false if owner?(new_owner)
    
    transaction do
      old_owner = owner
      update!(owner: new_owner)
      
      # Log the activity
      Activity.log_team_ownership_transferred(old_owner, new_owner: new_owner) if defined?(Activity)
    end
    
    true
  rescue => e
    Rails.logger.error "Failed to transfer team ownership: #{e.message}"
    false
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

  def active?
    is_active?
  end

  def activity_summary
    {
      total_events: events.count,
      recent_events: events.where('created_at > ?', 7.days.ago).count,
      total_alerts: alerts.count,
      active_alerts: alerts.where(enabled: true).count
    }
  end

  def member_summary
    users.includes(:role).map do |user|
      {
        id: user.id,
        email: user.email,
        name: user.full_name,
        role: user.role.name,
        last_login: user.last_login_at,
        status: user.locked_at ? 'locked' : 'active'
      }
    end
  end

  def invitation_summary
    invitations.where(status: 'pending').includes(:role, :invited_by).map do |invitation|
      {
        id: invitation.id,
        email: invitation.email,
        role: invitation.role.name,
        invited_by: invitation.invited_by.full_name,
        expires_at: invitation.expires_at,
        created_at: invitation.created_at
      }
    end
  end

  def settings_summary
    {
      notifications_enabled: get_setting('notifications_enabled', true),
      auto_archive_days: get_setting('auto_archive_days', 30),
      max_members: get_setting('max_members', 50),
      allow_public_events: get_setting('allow_public_events', false)
    }
  end

  def set_setting(key, value)
    current_settings = settings.is_a?(Hash) ? settings : {}
    current_settings[key.to_s] = value
    update(settings: current_settings)
  end

  def remove_setting(key)
    return unless settings.is_a?(Hash)
    current_settings = settings
    current_settings.delete(key.to_s)
    update(settings: current_settings)
  end

  def pending_invitations
    invitations.where(status: 'pending')
  end

  private

  def set_default_settings
    return if settings.present?
    
    self.settings = {
      'notifications_enabled' => true,
      'auto_archive_days' => 30,
      'max_members' => 50,
      'allow_public_events' => false,
      'default_role' => 'member',
      'invitation_expiry_days' => 7
    }
  end

  def log_team_creation
    AuditLog.create!(
      user: owner,
      action: "team_created",
      resource_type: "Team",
      resource_id: id,
      details: {
        team_name: name,
        description: description,
        settings: settings
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
        changes: saved_changes.except('updated_at'),
        previous_values: saved_changes.transform_values(&:first)
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
        events_count: events.count
      }
    )
  rescue => e
    Rails.logger.error "Failed to log team deletion: #{e.message}"
  end
end
