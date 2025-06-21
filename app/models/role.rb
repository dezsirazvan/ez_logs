class Role < ApplicationRecord
  # Associations
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true, length: { minimum: 2, maximum: 50 }
  validates :description, presence: true, length: { maximum: 500 }
  validates :is_active, inclusion: { in: [ true, false ] }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:name) }

  # Callbacks
  before_validation :set_default_permissions

  # Class methods
  def self.admin
    find_by(name: "admin")
  end

  def self.developer
    find_by(name: "developer")
  end

  def self.viewer
    find_by(name: "viewer")
  end

  def self.read_only
    find_by(name: "read_only")
  end

  def self.create_default_roles
    return if count > 0

    create!(
      name: "admin",
      description: "Full system administrator with all permissions",
      permissions: admin_permissions,
      is_active: true
    )

    create!(
      name: "developer",
      description: "Developer with full access to events and analytics",
      permissions: developer_permissions,
      is_active: true
    )

    create!(
      name: "viewer",
      description: "Standard user with read access to events and basic analytics",
      permissions: viewer_permissions,
      is_active: true
    )

    create!(
      name: "read_only",
      description: "Read-only access to events only",
      permissions: read_only_permissions,
      is_active: true
    )
  end

  def self.admin_permissions
    {
      "users" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true,
        "manage_roles" => true
      },
      "teams" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true,
        "manage_members" => true
      },
      "events" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true,
        "export" => true
      },
      "analytics" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true,
        "export" => true
      },
      "alerts" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true,
        "manage" => true
      },
      "audit_logs" => {
        "read" => true,
        "export" => true
      },
      "api_keys" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true
      },
      "system" => {
        "settings" => true,
        "maintenance" => true,
        "backup" => true
      }
    }
  end

  def self.developer_permissions
    {
      "users" => {
        "read" => true,
        "update" => true
      },
      "teams" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "manage_members" => true
      },
      "events" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true,
        "export" => true
      },
      "analytics" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "export" => true
      },
      "alerts" => {
        "read" => true,
        "create" => true,
        "update" => true
      },
      "api_keys" => {
        "read" => true,
        "create" => true,
        "update" => true,
        "delete" => true
      }
    }
  end

  def self.viewer_permissions
    {
      "users" => {
        "read" => true
      },
      "teams" => {
        "read" => true
      },
      "events" => {
        "read" => true,
        "export" => true
      },
      "analytics" => {
        "read" => true
      },
      "alerts" => {
        "read" => true
      },
      "api_keys" => {
        "read" => true,
        "create" => true
      }
    }
  end

  def self.read_only_permissions
    {
      "events" => {
        "read" => true
      },
      "analytics" => {
        "read" => true
      }
    }
  end

  # Instance methods
  def admin?
    name == "admin"
  end

  def developer?
    name == "developer"
  end

  def viewer?
    name == "viewer"
  end

  def read_only?
    name == "read_only"
  end

  def can_access?(resource, action = nil)
    return false unless is_active?

    permissions_hash = permissions.is_a?(Hash) ? permissions : {}
    resource_permissions = permissions_hash[resource.to_s] || {}

    if action
      resource_permissions[action.to_s] == true
    else
      resource_permissions.values.any?
    end
  end

  def grant_permission(resource, action)
    current_permissions = permissions.is_a?(Hash) ? permissions : {}
    current_permissions[resource.to_s] ||= {}
    current_permissions[resource.to_s][action.to_s] = true

    update(permissions: current_permissions)
  end

  def revoke_permission(resource, action)
    current_permissions = permissions.is_a?(Hash) ? permissions : {}
    return unless current_permissions[resource.to_s]

    current_permissions[resource.to_s].delete(action.to_s)
    current_permissions.delete(resource.to_s) if current_permissions[resource.to_s].empty?

    update(permissions: current_permissions)
  end

  def permission_summary
    return {} unless permissions.is_a?(Hash)

    summary = {}
    permissions.each do |resource, actions|
      summary[resource] = actions.keys.select { |action| actions[action] == true }
    end
    summary
  end

  def deactivate!
    update(is_active: false)
  end

  def activate!
    update(is_active: true)
  end

  def can_be_deleted?
    users.count == 0 && invitations.count == 0
  end

  private

  def set_default_permissions
    return if permissions.present?

    case name&.downcase
    when "admin"
      self.permissions = self.class.admin_permissions
    when "developer"
      self.permissions = self.class.developer_permissions
    when "viewer"
      self.permissions = self.class.viewer_permissions
    when "read_only"
      self.permissions = self.class.read_only_permissions
    end
  end
end
