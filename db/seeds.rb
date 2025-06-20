# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding EZLogs database..."

# Create default roles
puts "Creating default roles..."
Role.create_default_roles

# Create admin user first
puts "Creating admin user..."
admin_role = Role.admin
admin_user = User.find_or_create_by(email: 'admin@ezlogs.com') do |user|
  user.first_name = 'System'
  user.last_name = 'Administrator'
  user.password = 'admin123456'
  user.password_confirmation = 'admin123456'
  user.role = admin_role
  user.confirmed_at = Time.current
  user.mfa_enabled = false
end

# Create admin team using direct SQL to avoid circular dependency
puts "Creating admin team..."
admin_team = Team.find_or_create_by(name: 'EZLogs Admin Team') do |team|
  team.description = 'Default administrative team for EZLogs system'
  team.user_id = admin_user.id
  team.owner_id = admin_user.id
  team.is_active = true
end

# Update admin user with team
admin_user.update(team: admin_team) if admin_user.team.nil?

# Create sample users for testing
puts "Creating sample users..."
developer_role = Role.developer
viewer_role = Role.viewer

# Sample developer
developer = User.find_or_create_by(email: 'developer@ezlogs.com') do |user|
  user.first_name = 'John'
  user.last_name = 'Developer'
  user.password = 'dev123456'
  user.password_confirmation = 'dev123456'
  user.role = developer_role
  user.confirmed_at = Time.current
  user.mfa_enabled = false
end

# Sample viewer
viewer = User.find_or_create_by(email: 'viewer@ezlogs.com') do |user|
  user.first_name = 'Jane'
  user.last_name = 'Viewer'
  user.password = 'view123456'
  user.password_confirmation = 'view123456'
  user.role = viewer_role
  user.confirmed_at = Time.current
  user.mfa_enabled = false
end

# Create sample teams
puts "Creating sample teams..."
dev_team = Team.find_or_create_by(name: 'Development Team') do |team|
  team.description = 'Team for development and testing'
  team.user_id = developer.id
  team.owner_id = developer.id
  team.is_active = true
end

viewer_team = Team.find_or_create_by(name: 'Viewer Team') do |team|
  team.description = 'Team for read-only access'
  team.user_id = viewer.id
  team.owner_id = viewer.id
  team.is_active = true
end

# Assign users to teams
developer.update(team: dev_team) if developer.team.nil?
viewer.update(team: viewer_team) if viewer.team.nil?

# Create sample API keys
puts "Creating sample API keys..."
admin_api_key = ApiKey.find_or_create_by(name: 'Admin API Key', user: admin_user) do |key|
  key.permissions = { 'events' => [ 'read', 'create', 'update', 'delete' ], 'analytics' => [ 'read' ] }
end

developer_api_key = ApiKey.find_or_create_by(name: 'Developer API Key', user: developer) do |key|
  key.permissions = { 'events' => [ 'read', 'create' ], 'analytics' => [ 'read' ] }
end

# Create sample audit logs
puts "Creating sample audit logs..."
AuditLog.find_or_create_by(action: 'system_initialized') do |log|
  log.user = admin_user
  log.action = 'system_initialized'
  log.details = {
    version: '1.0.0',
    roles_created: Role.count,
    users_created: User.count,
    teams_created: Team.count
  }
end

puts "✅ Database seeded successfully!"
puts "📧 Admin email: admin@ezlogs.com"
puts "🔑 Admin password: admin123456"
puts "📧 Developer email: developer@ezlogs.com"
puts "🔑 Developer password: dev123456"
puts "📧 Viewer email: viewer@ezlogs.com"
puts "🔑 Viewer password: view123456"
puts ""
puts "🔑 Admin API Key: #{admin_api_key.key}"
puts "🔑 Developer API Key: #{developer_api_key.key}"
puts ""
puts "⚠️  IMPORTANT: Change these passwords in production!"
