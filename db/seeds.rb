# EZLogs UniversalEvent Seed Data
# This creates 100+ realistic events with the 3 main types from Ruby agent:
# - http.request (HTTP requests and API calls)
# - data.change (Database operations and model changes)
# - job.execution (Background job processing)

puts "🌱 Seeding EZLogs with UniversalEvent data..."

# Get or create company
company = Company.first_or_create!(
  name: "EZLogs Demo Company",
  domain: "ezlogs.demo",
  status: "active"
)

# Get or create users
users = []
5.times do |i|
  user = User.find_or_create_by(email: "user#{i+1}@ezlogs.demo") do |u|
    u.first_name = ["John", "Jane", "Mike", "Sarah", "Alex"][i]
    u.last_name = ["Smith", "Johnson", "Williams", "Brown", "Davis"][i]
    u.password = "password123"
    u.password_confirmation = "password123"
    u.company = company
    u.role = Role.find_or_create_by(name: "user")
    u.confirmed_at = Time.current
    u.last_sign_in_at = rand(1.hour.ago..Time.current)
  end
  users << user
end

# Helper methods
def generate_correlation_id
  "corr_#{SecureRandom.hex(8)}"
end

def generate_event_id
  "evt_#{SecureRandom.hex(12)}"
end

def create_actor(user = nil)
  if user
    {
      type: 'user',
      id: user.id.to_s,
      email: user.email,
      name: "#{user.first_name} #{user.last_name}"
    }
  else
    {
      type: 'system',
      id: 'system',
      name: 'System Process'
    }
  end
end

def create_subject(type, id, additional = {})
  {
    type: type,
    id: id.to_s
  }.merge(additional)
end

def create_platform
  {
    name: 'rails',
    version: '7.1.0',
    environment: 'development',
    hostname: "app-server-#{rand(1..3)}",
    pid: rand(1000..9999)
  }
end

# Clear existing events
puts "Clearing existing events..."
Event.delete_all

# 1. User Authentication Flow (5 events)
puts "Creating user authentication flows..."
auth_correlation = generate_correlation_id
user = users.first

auth_events = [
  {
    event_id: generate_event_id,
    correlation_id: auth_correlation,
    event_type: 'http.request',
    action: 'GET /users/sign_in',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/users/sign_in', { method: 'GET' }),
    metadata: {
      status: 200,
      duration: rand(50..150) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      ip_address: '192.168.1.100'
    },
    timestamp: 10.minutes.ago,
    correlation: { flow_type: 'user_authentication', step: 'login_page_loaded' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  },
  {
    event_id: generate_event_id,
    correlation_id: auth_correlation,
    event_type: 'http.request',
    action: 'POST /users/sign_in',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/users/sign_in', { method: 'POST' }),
    metadata: {
      status: 200,
      duration: rand(200..500) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      ip_address: '192.168.1.100',
      params: { email: user.email, password: '[REDACTED]' }
    },
    timestamp: 10.minutes.ago + 2.seconds,
    correlation: { flow_type: 'user_authentication', step: 'login_attempt' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  },
  {
    event_id: generate_event_id,
    correlation_id: auth_correlation,
    event_type: 'data.change',
    action: 'user.login',
    actor: create_actor(user),
    subject: create_subject('user', user.id),
    metadata: {
      changes: { last_sign_in_at: [nil, Time.current] },
      duration: rand(10..50) / 1000.0
    },
    timestamp: 10.minutes.ago + 2.1.seconds,
    correlation: { flow_type: 'user_authentication', step: 'login_success' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'database'
  },
  {
    event_id: generate_event_id,
    correlation_id: auth_correlation,
    event_type: 'http.request',
    action: 'GET /dashboard',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/dashboard', { method: 'GET' }),
    metadata: {
      status: 200,
      duration: rand(100..300) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      ip_address: '192.168.1.100'
    },
    timestamp: 10.minutes.ago + 3.seconds,
    correlation: { flow_type: 'user_authentication', step: 'dashboard_loaded' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  },
  {
    event_id: generate_event_id,
    correlation_id: auth_correlation,
    event_type: 'data.change',
    action: 'dashboard.viewed',
    actor: create_actor(user),
    subject: create_subject('page', 'dashboard'),
    metadata: {
      duration: rand(50..200) / 1000.0,
      events_count: rand(50..200)
    },
    timestamp: 10.minutes.ago + 3.1.seconds,
    correlation: { flow_type: 'user_authentication', step: 'dashboard_interaction' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  }
]

# 2. API Request Flow (4 events)
puts "Creating API request flows..."
api_correlation = generate_correlation_id

api_events = [
  {
    event_id: generate_event_id,
    correlation_id: api_correlation,
    event_type: 'http.request',
    action: 'GET /api/v1/events',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/api/v1/events', { method: 'GET' }),
    metadata: {
      status: 200,
      duration: rand(100..500) / 1000.0,
      user_agent: 'EZLogs-Ruby-Agent/1.0.0',
      ip_address: '10.0.0.50',
      params: { page: 1, per_page: 20, event_type: 'http.request' }
    },
    timestamp: 8.minutes.ago,
    correlation: { flow_type: 'api_request', step: 'request_received' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'api'
  },
  {
    event_id: generate_event_id,
    correlation_id: api_correlation,
    event_type: 'data.change',
    action: 'events.list',
    actor: create_actor(user),
    subject: create_subject('collection', 'events'),
    metadata: {
      count: 15,
      duration: rand(20..100) / 1000.0,
      filters: { event_type: 'http.request' }
    },
    timestamp: 8.minutes.ago + 0.05.seconds,
    correlation: { flow_type: 'api_request', step: 'data_retrieved' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'database'
  },
  {
    event_id: generate_event_id,
    correlation_id: api_correlation,
    event_type: 'http.request',
    action: 'POST /api/v1/events',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/api/v1/events', { method: 'POST' }),
    metadata: {
      status: 201,
      duration: rand(150..400) / 1000.0,
      user_agent: 'EZLogs-Ruby-Agent/1.0.0',
      ip_address: '10.0.0.50',
      params: { event_type: 'http.request', action: 'GET /api/users' }
    },
    timestamp: 8.minutes.ago + 0.1.seconds,
    correlation: { flow_type: 'api_request', step: 'event_created' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'api'
  },
  {
    event_id: generate_event_id,
    correlation_id: api_correlation,
    event_type: 'data.change',
    action: 'event.create',
    actor: create_actor(user),
    subject: create_subject('event', SecureRandom.hex(8)),
    metadata: {
      duration: rand(10..50) / 1000.0,
      event_type: 'http.request',
      action: 'GET /api/users'
    },
    timestamp: 8.minutes.ago + 0.15.seconds,
    correlation: { flow_type: 'api_request', step: 'database_updated' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'database'
  }
]

# 3. Background Job Flow (6 events)
puts "Creating background job flows..."
job_correlation = generate_correlation_id

job_events = [
  {
    event_id: generate_event_id,
    correlation_id: job_correlation,
    event_type: 'job.execution',
    action: 'EmailNotificationJob.enqueued',
    actor: create_actor,
    subject: create_subject('job', 'EmailNotificationJob'),
    metadata: {
      job_id: SecureRandom.hex(8),
      queue: 'default',
      arguments: { user_id: user.id, notification_type: 'welcome' }
    },
    timestamp: 6.minutes.ago,
    correlation: { flow_type: 'background_job', step: 'job_enqueued' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'sidekiq'
  },
  {
    event_id: generate_event_id,
    correlation_id: job_correlation,
    event_type: 'job.execution',
    action: 'EmailNotificationJob.started',
    actor: create_actor,
    subject: create_subject('job', 'EmailNotificationJob'),
    metadata: {
      job_id: SecureRandom.hex(8),
      worker_id: "worker-#{rand(1..5)}",
      duration: rand(500..2000) / 1000.0
    },
    timestamp: 6.minutes.ago + 0.5.seconds,
    correlation: { flow_type: 'background_job', step: 'job_started' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'sidekiq'
  },
  {
    event_id: generate_event_id,
    correlation_id: job_correlation,
    event_type: 'data.change',
    action: 'email.prepared',
    actor: create_actor,
    subject: create_subject('email', SecureRandom.hex(8)),
    metadata: {
      recipient: user.email,
      template: 'welcome_email',
      duration: rand(100..500) / 1000.0
    },
    timestamp: 6.minutes.ago + 0.8.seconds,
    correlation: { flow_type: 'background_job', step: 'email_prepared' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'database'
  },
  {
    event_id: generate_event_id,
    correlation_id: job_correlation,
    event_type: 'http.request',
    action: 'POST /api/sendgrid/send',
    actor: create_actor,
    subject: create_subject('endpoint', '/api/sendgrid/send', { method: 'POST' }),
    metadata: {
      status: 202,
      duration: rand(200..800) / 1000.0,
      user_agent: 'SendGrid-Ruby/6.0.0',
      ip_address: '10.0.0.100'
    },
    timestamp: 6.minutes.ago + 1.0.seconds,
    correlation: { flow_type: 'background_job', step: 'email_sent' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'api'
  },
  {
    event_id: generate_event_id,
    correlation_id: job_correlation,
    event_type: 'data.change',
    action: 'email.sent',
    actor: create_actor,
    subject: create_subject('email', SecureRandom.hex(8)),
    metadata: {
      recipient: user.email,
      message_id: SecureRandom.hex(16),
      duration: rand(50..200) / 1000.0
    },
    timestamp: 6.minutes.ago + 1.1.seconds,
    correlation: { flow_type: 'background_job', step: 'email_recorded' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'database'
  },
  {
    event_id: generate_event_id,
    correlation_id: job_correlation,
    event_type: 'job.execution',
    action: 'EmailNotificationJob.completed',
    actor: create_actor,
    subject: create_subject('job', 'EmailNotificationJob'),
    metadata: {
      job_id: SecureRandom.hex(8),
      duration: rand(500..2000) / 1000.0,
      result: 'email_sent',
      recipient: user.email
    },
    timestamp: 6.minutes.ago + 1.2.seconds,
    correlation: { flow_type: 'background_job', step: 'job_completed' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'sidekiq'
  }
]

# 4. User Profile Update Flow (4 events)
puts "Creating user profile update flows..."
profile_correlation = generate_correlation_id

profile_events = [
  {
    event_id: generate_event_id,
    correlation_id: profile_correlation,
    event_type: 'http.request',
    action: 'GET /users/profile/edit',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/users/profile/edit', { method: 'GET' }),
    metadata: {
      status: 200,
      duration: rand(80..200) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      ip_address: '192.168.1.100'
    },
    timestamp: 4.minutes.ago,
    correlation: { flow_type: 'user_profile', step: 'edit_page_loaded' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  },
  {
    event_id: generate_event_id,
    correlation_id: profile_correlation,
    event_type: 'http.request',
    action: 'PUT /users/profile',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/users/profile', { method: 'PUT' }),
    metadata: {
      status: 200,
      duration: rand(150..400) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      ip_address: '192.168.1.100',
      params: { first_name: 'Jonathan', last_name: 'Smith' }
    },
    timestamp: 4.minutes.ago + 1.seconds,
    correlation: { flow_type: 'user_profile', step: 'profile_update_request' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  },
  {
    event_id: generate_event_id,
    correlation_id: profile_correlation,
    event_type: 'data.change',
    action: 'user.update',
    actor: create_actor(user),
    subject: create_subject('user', user.id),
    metadata: {
      changes: { first_name: ['John', 'Jonathan'], last_name: ['Doe', 'Smith'] },
      duration: rand(20..80) / 1000.0
    },
    timestamp: 4.minutes.ago + 1.1.seconds,
    correlation: { flow_type: 'user_profile', step: 'database_update' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'database'
  },
  {
    event_id: generate_event_id,
    correlation_id: profile_correlation,
    event_type: 'http.request',
    action: 'GET /users/profile',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/users/profile', { method: 'GET' }),
    metadata: {
      status: 200,
      duration: rand(60..150) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      ip_address: '192.168.1.100'
    },
    timestamp: 4.minutes.ago + 2.seconds,
    correlation: { flow_type: 'user_profile', step: 'profile_viewed' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  }
]

# 5. Error Flow (3 events)
puts "Creating error flows..."
error_correlation = generate_correlation_id

error_events = [
  {
    event_id: generate_event_id,
    correlation_id: error_correlation,
    event_type: 'http.request',
    action: 'POST /api/v1/events',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/api/v1/events', { method: 'POST' }),
    metadata: {
      status: 422,
      duration: rand(200..800) / 1000.0,
      error: 'Validation failed',
      error_details: { event_type: ['is required'], action: ['is required'] }
    },
    timestamp: 30.seconds.ago,
    correlation: { flow_type: 'api_request', step: 'validation_error' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'api',
    validation_errors: ['event_type is required', 'action is required']
  },
  {
    event_id: generate_event_id,
    correlation_id: error_correlation,
    event_type: 'data.change',
    action: 'error.logged',
    actor: create_actor,
    subject: create_subject('error', SecureRandom.hex(8)),
    metadata: {
      error_type: 'ValidationError',
      message: 'Event validation failed',
      duration: rand(10..50) / 1000.0
    },
    timestamp: 30.seconds.ago + 0.1.seconds,
    correlation: { flow_type: 'api_request', step: 'error_logged' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'database'
  },
  {
    event_id: generate_event_id,
    correlation_id: error_correlation,
    event_type: 'http.request',
    action: 'GET /api/v1/health',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/api/v1/health', { method: 'GET' }),
    metadata: {
      status: 500,
      duration: rand(1000..3000) / 1000.0,
      error: 'Database connection failed',
      error_details: { database: 'postgresql', connection_pool: 'exhausted' }
    },
    timestamp: 30.seconds.ago + 0.2.seconds,
    correlation: { flow_type: 'api_request', step: 'health_check_failed' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'api'
  }
]

# Combine all correlated events
all_correlated_events = auth_events + api_events + job_events + profile_events + error_events

# Create correlated events
puts "Creating #{all_correlated_events.length} correlated events..."
all_correlated_events.each do |event_data|
  Event.create!(
    company: company,
    event_id: event_data[:event_id],
    correlation_id: event_data[:correlation_id],
    event_type: event_data[:event_type],
    action: event_data[:action],
    actor: event_data[:actor],
    subject: event_data[:subject],
    metadata: event_data[:metadata],
    timestamp: event_data[:timestamp],
    correlation: event_data[:correlation],
    correlation_context: event_data[:correlation_context],
    payload: event_data[:payload],
    platform: event_data[:platform],
    source: event_data[:source],
    validation_errors: event_data[:validation_errors] || []
  )
end

# Create standalone events (80+ events)
puts "Creating standalone events..."

80.times do |i|
  event_types = ['http.request', 'data.change', 'job.execution']
  event_type = event_types.sample
  user = users.sample
  correlation_id = generate_correlation_id
  
  case event_type
  when 'http.request'
    actions = [
      'GET /dashboard', 'POST /api/v1/events', 'GET /users/profile', 
      'DELETE /api/v1/users/123', 'PUT /api/v1/settings', 'GET /events',
      'POST /api/v1/alerts', 'GET /teams', 'POST /api/v1/webhooks',
      'GET /analytics', 'POST /api/v1/import', 'GET /reports',
      'GET /api/v1/health', 'POST /api/v1/webhooks/stripe',
      'GET /api/v1/metrics', 'POST /api/v1/notifications'
    ]
    action = actions.sample
    statuses = [200, 201, 204, 400, 401, 403, 404, 422, 500]
    status = statuses.sample
    
    metadata = {
      status: status,
      duration: rand(50..2000) / 1000.0,
      user_agent: ['Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', 
                   'EZLogs-Ruby-Agent/1.0.0', 
                   'PostmanRuntime/7.32.3',
                   'curl/7.68.0'].sample,
      ip_address: "192.168.1.#{rand(1..255)}"
    }
    
    if status >= 400
      metadata[:error] = ['Validation failed', 'Unauthorized', 'Not found', 'Internal server error'].sample
    end
    
  when 'data.change'
    actions = [
      'user.create', 'user.update', 'user.delete', 'team.create', 'api_key.create',
      'event.create', 'event.update', 'alert.create', 'alert.update', 'role.create',
      'company.update', 'invitation.create', 'invitation.accept', 'log.create',
      'settings.update', 'preferences.save', 'notification.create', 'metric.record'
    ]
    action = actions.sample
    
    metadata = {
      changes: { field: ['old_value', 'new_value'] },
      duration: rand(10..200) / 1000.0,
      table: ['users', 'events', 'teams', 'api_keys', 'alerts', 'settings', 'notifications'].sample
    }
    
  when 'job.execution'
    actions = [
      'EmailJob.enqueued', 'CleanupJob.started', 'ReportJob.completed', 'SyncJob.failed',
      'ImportJob.enqueued', 'ExportJob.started', 'BackupJob.completed', 'NotificationJob.failed',
      'AnalyticsJob.enqueued', 'MaintenanceJob.started', 'IndexJob.completed',
      'WebhookJob.enqueued', 'MetricsJob.started', 'AuditJob.completed'
    ]
    action = actions.sample
    
    metadata = {
      job_id: SecureRandom.hex(8),
      queue: ['default', 'high', 'low', 'critical'].sample,
      duration: rand(100..10000) / 1000.0
    }
    
    if action.include?('failed')
      metadata[:error] = ['Connection timeout', 'Invalid data', 'Resource not found'].sample
    end
  end

  # Random timestamp within the last 24 hours
  timestamp = rand(24.hours.ago..Time.current)

  Event.create!(
    company: company,
    event_id: generate_event_id,
    correlation_id: correlation_id,
    event_type: event_type,
    action: action,
    actor: create_actor(user),
    subject: create_subject('resource', rand(1..1000)),
    metadata: metadata,
    timestamp: timestamp,
    correlation: { flow_type: 'standalone', step: 'single_event' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: ['web', 'api', 'database', 'sidekiq'].sample
  )
end

puts "✅ Successfully created #{Event.count} UniversalEvent records!"
puts "📊 Events by type:"
Event.group(:event_type).count.each do |type, count|
  puts "  #{type}: #{count}"
end

puts "🔗 Correlation flows created:"
puts "- User Authentication Flow: #{auth_correlation}"
puts "- API Request Flow: #{api_correlation}"
puts "- Background Job Flow: #{job_correlation}"
puts "- User Profile Flow: #{profile_correlation}"
puts "- Error Flow: #{error_correlation}"

puts "🎉 Seeding completed! Visit http://localhost:3000/dashboard/events to see your events." 