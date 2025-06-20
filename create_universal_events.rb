#!/usr/bin/env ruby

# Create realistic UniversalEvent data inspired by the Ruby agent
# This script creates events that match the UniversalEvent schema

puts "Creating UniversalEvent data..."

# Get the first company
company = Company.first
unless company
  puts "No company found. Please create a company first."
  exit 1
end

# Get some users for actors
users = company.users.limit(5)
if users.empty?
  puts "No users found. Please create users first."
  exit 1
end

# Helper method to generate random correlation ID
def generate_correlation_id
  "corr_#{SecureRandom.hex(8)}"
end

# Helper method to generate random event ID
def generate_event_id
  "evt_#{SecureRandom.hex(12)}"
end

# Helper method to create actor JSON
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

# Helper method to create subject JSON
def create_subject(type, id, additional = {})
  {
    type: type,
    id: id.to_s
  }.merge(additional)
end

# Helper method to create platform info
def create_platform
  {
    name: 'rails',
    version: '7.1.0',
    environment: 'development',
    hostname: 'app-server-1',
    pid: rand(1000..9999)
  }
end

# Create HTTP request events
puts "Creating HTTP request events..."
http_correlation = generate_correlation_id

# User login flow
user = users.first
login_events = [
  {
    event_id: generate_event_id,
    correlation_id: http_correlation,
    event_type: 'http.request',
    action: 'POST /users/sign_in',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/users/sign_in', { method: 'POST' }),
    metadata: {
      status: 200,
      duration: rand(50..200) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      ip_address: '192.168.1.100',
      params: { email: user.email, password: '[REDACTED]' }
    },
    timestamp: 5.minutes.ago,
    correlation: { flow_type: 'user_authentication', step: 'login_attempt' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  },
  {
    event_id: generate_event_id,
    correlation_id: http_correlation,
    event_type: 'data.change',
    action: 'user.login',
    actor: create_actor(user),
    subject: create_subject('user', user.id),
    metadata: {
      changes: { last_sign_in_at: [nil, Time.current] },
      duration: rand(10..50) / 1000.0
    },
    timestamp: 5.minutes.ago + 0.1.seconds,
    correlation: { flow_type: 'user_authentication', step: 'login_success' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'database'
  }
]

# API request flow
api_correlation = generate_correlation_id
api_events = [
  {
    event_id: generate_event_id,
    correlation_id: api_correlation,
    event_type: 'http.request',
    action: 'GET /api/v1/users',
    actor: create_actor(user),
    subject: create_subject('endpoint', '/api/v1/users', { method: 'GET' }),
    metadata: {
      status: 200,
      duration: rand(100..500) / 1000.0,
      user_agent: 'EZLogs-Ruby-Agent/1.0.0',
      ip_address: '10.0.0.50',
      params: { page: 1, per_page: 20 }
    },
    timestamp: 3.minutes.ago,
    correlation: { flow_type: 'api_request', step: 'request_received' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'api'
  },
  {
    event_id: generate_event_id,
    correlation_id: api_correlation,
    event_type: 'data.change',
    action: 'user.list',
    actor: create_actor(user),
    subject: create_subject('collection', 'users'),
    metadata: {
      count: 15,
      duration: rand(20..100) / 1000.0,
      filters: { active: true }
    },
    timestamp: 3.minutes.ago + 0.05.seconds,
    correlation: { flow_type: 'api_request', step: 'data_retrieved' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'database'
  }
]

# Job execution flow
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
    timestamp: 2.minutes.ago,
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
    timestamp: 2.minutes.ago + 0.5.seconds,
    correlation: { flow_type: 'background_job', step: 'job_started' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'sidekiq'
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
    timestamp: 2.minutes.ago + 1.2.seconds,
    correlation: { flow_type: 'background_job', step: 'job_completed' },
    correlation_context: { job_class: 'EmailNotificationJob' },
    platform: create_platform,
    source: 'sidekiq'
  }
]

# User action flow
user_action_correlation = generate_correlation_id
user_action_events = [
  {
    event_id: generate_event_id,
    correlation_id: user_action_correlation,
    event_type: 'user.action',
    action: 'profile.updated',
    actor: create_actor(user),
    subject: create_subject('user', user.id),
    metadata: {
      changes: { first_name: ['John', 'Jonathan'], last_name: ['Doe', 'Smith'] },
      duration: rand(50..150) / 1000.0
    },
    timestamp: 1.minute.ago,
    correlation: { flow_type: 'user_profile', step: 'profile_update' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'web'
  },
  {
    event_id: generate_event_id,
    correlation_id: user_action_correlation,
    event_type: 'data.change',
    action: 'user.update',
    actor: create_actor(user),
    subject: create_subject('user', user.id),
    metadata: {
      changes: { first_name: ['John', 'Jonathan'], last_name: ['Doe', 'Smith'] },
      duration: rand(20..80) / 1000.0
    },
    timestamp: 1.minute.ago + 0.1.seconds,
    correlation: { flow_type: 'user_profile', step: 'database_update' },
    correlation_context: { session_id: SecureRandom.hex(16) },
    platform: create_platform,
    source: 'database'
  }
]

# System event flow
system_correlation = generate_correlation_id
system_events = [
  {
    event_id: generate_event_id,
    correlation_id: system_correlation,
    event_type: 'system.event',
    action: 'database.connection.pool.exhausted',
    actor: create_actor,
    subject: create_subject('system', 'database_pool'),
    metadata: {
      pool_size: 20,
      active_connections: 20,
      waiting_connections: 5,
      duration: rand(1000..5000) / 1000.0
    },
    timestamp: 30.seconds.ago,
    correlation: { flow_type: 'system_monitoring', step: 'pool_exhausted' },
    correlation_context: { component: 'database', severity: 'warning' },
    platform: create_platform,
    source: 'system'
  },
  {
    event_id: generate_event_id,
    correlation_id: system_correlation,
    event_type: 'system.event',
    action: 'database.connection.pool.recovered',
    actor: create_actor,
    subject: create_subject('system', 'database_pool'),
    metadata: {
      pool_size: 20,
      active_connections: 15,
      waiting_connections: 0,
      duration: rand(100..500) / 1000.0
    },
    timestamp: 25.seconds.ago,
    correlation: { flow_type: 'system_monitoring', step: 'pool_recovered' },
    correlation_context: { component: 'database', severity: 'info' },
    platform: create_platform,
    source: 'system'
  }
]

# Error flow
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
    timestamp: 10.seconds.ago,
    correlation: { flow_type: 'api_request', step: 'validation_error' },
    correlation_context: { api_version: 'v1', client_id: 'ruby_agent_001' },
    platform: create_platform,
    source: 'api',
    validation_errors: ['event_type is required', 'action is required']
  }
]

# Combine all events
all_events = login_events + api_events + job_events + user_action_events + system_events + error_events

# Create events in database
puts "Creating #{all_events.length} events..."

all_events.each do |event_data|
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

puts "Successfully created #{all_events.length} UniversalEvent records!"
puts "Correlation flows created:"
puts "- HTTP Login Flow: #{http_correlation}"
puts "- API Request Flow: #{api_correlation}"
puts "- Job Execution Flow: #{job_correlation}"
puts "- User Action Flow: #{user_action_correlation}"
puts "- System Event Flow: #{system_correlation}"
puts "- Error Flow: #{error_correlation}"

# Create some additional standalone events
puts "Creating additional standalone events..."

20.times do |i|
  event_types = ['http.request', 'data.change', 'job.execution', 'user.action', 'system.event']
  event_type = event_types.sample
  
  case event_type
  when 'http.request'
    action = ['GET /dashboard', 'POST /api/v1/events', 'GET /users/profile', 'DELETE /api/v1/users/123'].sample
    metadata = {
      status: [200, 201, 404, 500].sample,
      duration: rand(50..1000) / 1000.0,
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    }
  when 'data.change'
    action = ['user.create', 'user.update', 'user.delete', 'team.create', 'api_key.create'].sample
    metadata = {
      changes: { field: ['old_value', 'new_value'] },
      duration: rand(10..100) / 1000.0
    }
  when 'job.execution'
    action = ['EmailJob.enqueued', 'CleanupJob.started', 'ReportJob.completed', 'SyncJob.failed'].sample
    metadata = {
      job_id: SecureRandom.hex(8),
      queue: ['default', 'high', 'low'].sample,
      duration: rand(100..5000) / 1000.0
    }
  when 'user.action'
    action = ['login', 'logout', 'password_change', 'mfa_enabled', 'profile_update'].sample
    metadata = {
      session_id: SecureRandom.hex(16),
      ip_address: "192.168.1.#{rand(1..255)}"
    }
  when 'system.event'
    action = ['memory.high', 'cpu.spike', 'disk.space.low', 'cache.miss', 'queue.backlog'].sample
    metadata = {
      metric: rand(50..95),
      threshold: 80,
      component: ['memory', 'cpu', 'disk', 'cache', 'queue'].sample
    }
  end

  Event.create!(
    company: company,
    event_id: generate_event_id,
    correlation_id: generate_correlation_id,
    event_type: event_type,
    action: action,
    actor: create_actor(users.sample),
    subject: create_subject('resource', rand(1..1000)),
    metadata: metadata,
    timestamp: rand(1.hour.ago..Time.current),
    correlation: { flow_type: 'standalone', step: 'single_event' },
    platform: create_platform,
    source: ['web', 'api', 'system', 'database'].sample
  )
end

puts "Created 20 additional standalone events!"
puts "Total events in database: #{Event.count}"
puts "Events by type:"
Event.group(:event_type).count.each do |type, count|
  puts "  #{type}: #{count}"
end 