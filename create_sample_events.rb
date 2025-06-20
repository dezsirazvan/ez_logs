# Create sample events for testing
puts "Creating sample events..."

company = Company.first
return puts "No company found. Please run seeds first." unless company

# Sample event types and actions
event_types = ['user', 'system', 'api', 'security', 'database']
actions = ['created', 'updated', 'deleted', 'login', 'logout', 'failed_login', 'api_call', 'error']
severities = ['info', 'warning', 'error', 'critical']

# Create events over the last 7 days
7.times do |day|
  # Create 3-8 events per day
  rand(3..8).times do
    timestamp = day.days.ago + rand(0..23).hours + rand(0..59).minutes
    
    Event.create!(
      company: company,
      event_type: event_types.sample,
      action: actions.sample,
      actor_type: ['User', 'System', 'API'].sample,
      actor_id: rand(1..10).to_s,
      subject_type: ['User', 'Order', 'Product', 'Payment'].sample,
      subject_id: rand(1..100).to_s,
      severity: severities.sample,
      source: ['web', 'api', 'mobile', 'system'].sample,
      metadata: {
        ip_address: "192.168.1.#{rand(1..255)}",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        session_id: SecureRandom.hex(8)
      },
      timestamp: timestamp
    )
  end
end

puts "Created #{Event.count} events!"
puts "Events by type: #{Event.group(:event_type).count}"
puts "Events by severity: #{Event.group(:severity).count}" 