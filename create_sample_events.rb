# Create sample events for testing
puts "Creating sample events..."

company = Company.first
return puts "No company found. Please run seeds first." unless company

# Sample event types and actions
event_types = ['user', 'system', 'api', 'security', 'database']
actions = ['created', 'updated', 'deleted', 'login', 'logout', 'failed_login', 'api_call', 'error']

# Create events over the last 7 days
7.times do |day|
  # Create 3-8 events per day
  rand(3..8).times do
    timestamp = day.days.ago + rand(0..23).hours + rand(0..59).minutes
    
    # Generate correlation ID for some events to create story flows
    correlation_id = rand(1..3) == 1 ? "corr_#{SecureRandom.hex(8)}" : nil
    
    Event.create!(
      company: company,
      event_id: "evt_#{SecureRandom.hex(8)}",
      correlation_id: correlation_id,
      event_type: event_types.sample,
      action: actions.sample,
      actor: {
        type: ['User', 'System', 'API'].sample,
        id: rand(1..10).to_s,
        email: "user#{rand(1..10)}@example.com"
      },
      subject: {
        type: ['User', 'Order', 'Product', 'Payment'].sample,
        id: rand(1..100).to_s
      },
      metadata: {
        ip_address: "192.168.1.#{rand(1..255)}",
        user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        session_id: SecureRandom.hex(8)
      },
      timestamp: timestamp,
      correlation: correlation_id ? { flow_id: correlation_id, step: rand(1..5) } : nil,
      correlation_context: correlation_id ? { component: 'sample', session_id: SecureRandom.hex(8) } : nil,
      source: ['web', 'api', 'mobile', 'system'].sample,
      tags: ['sample', 'test']
    )
  end
end

puts "Created #{Event.count} events!"
puts "Events by type: #{Event.group(:event_type).count}"
puts "Story flows: #{Event.where.not(correlation_id: [nil, '']).group(:correlation_id).having('COUNT(*) > 1').count}" 