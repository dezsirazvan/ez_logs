require 'set'

class StoryReconstructor
  STORY_TIME_WINDOW = 30.seconds # Events within 30 seconds can be part of the same story
  
  # Main method to find a complete story for a given correlation ID
  def self.find_complete_story(correlation_id, company_id: nil)
    return empty_story unless correlation_id.present?
    
    # Start with the primary events
    primary_events = find_primary_events(correlation_id, company_id)
    return empty_story if primary_events.empty?
    
    # Find all related events that should be part of the same story
    all_related_events = find_all_related_events(primary_events, company_id)
    
    # Build the complete story
    build_story_response(all_related_events, correlation_id)
  end
  
  # Find all stories and reconstruct them properly
  def self.find_all_complete_stories(company)
    # Get all events for the company, ordered by time
    all_events = company.events.includes(:company).order(:created_at)
    
    # Group events by their primary_correlation_id
    story_groups = group_events_by_primary_correlation(all_events)
    
    # Convert each group into a story with metadata
    story_groups.map.with_index do |(primary_correlation_id, events), index|
      create_story_from_events(events, primary_correlation_id, index + 1)
    end
  end
  
  def self.find_all_events_in_story(primary_event)
    # Extract primary correlation ID from this event
    primary_correlation_id = extract_primary_correlation_id(primary_event)
    return [primary_event] unless primary_correlation_id
    
    # Find all events with the same primary_correlation_id
    primary_event.company.events
      .select { |event| extract_primary_correlation_id(event) == primary_correlation_id }
      .sort_by(&:created_at)
  end
  
  private
  
  # Find events that match the given correlation ID
  def self.find_primary_events(correlation_id, company_id)
    base_query = company_id ? Event.where(company_id: company_id) : Event
    base_query.where(correlation_id: correlation_id).order(:timestamp)
  end
  
  # Find all events that should be part of the same story
  def self.find_all_related_events(primary_events, company_id)
    return primary_events if primary_events.empty?
    
    # For backward compatibility with the existing method signature
    primary_correlation_id = extract_primary_correlation_id(primary_events.first)
    return primary_events unless primary_correlation_id.present?
    
    base_query = company_id ? Event.where(company_id: company_id) : Event
    find_all_events_in_story(base_query, primary_correlation_id)
  end
  
  # Find all events that belong to the same story using primary_correlation_id
  def self.find_all_events_in_story(base_query, primary_correlation_id)
    all_events = []
    
    # Method 1: Find events with matching primary_correlation_id in correlation field
    events_by_primary = base_query.where("correlation::text LIKE ?", "%\"primary_correlation_id\":\"#{primary_correlation_id}\"%")
    all_events.concat(events_by_primary.to_a)
    
    # Method 2: Find events with matching primary_correlation_id in correlation_context field
    events_by_context = base_query.where("correlation_context::text LIKE ?", "%\"primary_correlation_id\":\"#{primary_correlation_id}\"%")
    all_events.concat(events_by_context.to_a)
    
    # Method 3: Find the initiating event itself (it might not reference itself)
    initiating_event = base_query.where(correlation_id: primary_correlation_id).first
    all_events << initiating_event if initiating_event
    
    # Remove duplicates and sort by timestamp
    all_events.uniq(&:id).sort_by(&:timestamp)
  end
  
  # Extract the primary correlation ID from an event
  def self.extract_primary_correlation_id(event)
    # Try correlation_context first (for initiating events)
    if event.correlation_context.present?
      context = event.correlation_context
      context = JSON.parse(context) if context.is_a?(String)
      return context['primary_correlation_id'] if context.is_a?(Hash) && context['primary_correlation_id']
    end
    
    # Try correlation field (for triggered events)
    if event.correlation.present?
      correlation = event.correlation
      correlation = JSON.parse(correlation) if correlation.is_a?(String)
      return correlation['primary_correlation_id'] if correlation.is_a?(Hash) && correlation['primary_correlation_id']
    end
    
    # Fallback to correlation_id
    event.correlation_id
  rescue JSON::ParserError
    event.correlation_id
  end
  
  # Extract unique actors from events
  def self.extract_actors(events)
    events.map(&:actor).compact.uniq
  end
  
  # Extract unique subjects from events
  def self.extract_subjects(events)
    events.map(&:subject).compact.uniq
  end
  
  # Extract request IDs from correlation data
  def self.extract_request_ids(events)
    events.map { |e| e.correlation&.dig('request_id') || e.correlation&.dig(:request_id) }
           .compact
           .uniq
  end
  
  # Determine the primary correlation ID for the story
  def self.determine_primary_correlation_id(events)
    # Look for explicit primary_correlation_id in any event
    events.each do |event|
      primary_id = extract_primary_correlation_id(event)
      return primary_id if primary_id.present?
    end
    
    # Fall back to the correlation_id of the earliest initiating event (depth=0)
    initiating_event = events.find do |e| 
      (e.correlation && e.correlation['depth'] == 0) ||
      (e.correlation_context && e.correlation_context['depth'] == 0)
    end
    return initiating_event.correlation_id if initiating_event
    
    # Fall back to the correlation_id of the earliest HTTP request
    http_event = events.find { |e| e.event_type == 'http.request' }
    return http_event.correlation_id if http_event
    
    # Fall back to the first event's correlation_id
    events.first&.correlation_id
  end
  
  # Categorize events by component type
  def self.categorize_events_by_component(events)
    components = {}
    
    events.each do |event|
      component = determine_event_component(event)
      components[component] ||= []
      components[component] << event
    end
    
    components
  end
  
  # Determine which component an event belongs to
  def self.determine_event_component(event)
    case event.event_type
    when 'http.request'
      'web'
    when 'data.change'
      'database'
    when 'job.execution'
      'background_job'
    when 'api.call'
      'api'
    when 'security'
      'security'
    else
      'system'
    end
  end
  
  # Generate a human-readable title for the story
  def self.generate_story_title(events)
    return 'Unknown Story' if events.empty?
    
    # Look for HTTP requests first
    http_event = events.find { |e| e.event_type == 'http.request' }
    if http_event
      return "#{http_event.action} Request"
    end
    
    # Look for database changes
    db_event = events.find { |e| e.event_type == 'data.change' }
    if db_event
      return "Data Change: #{db_event.action}"
    end
    
    # Look for job executions
    job_event = events.find { |e| e.event_type == 'job.execution' }
    if job_event
      return "Background Job: #{job_event.action}"
    end
    
    # Default to the first event's action
    events.first.action
  end
  
  # Build the complete story response
  def self.build_story_response(events, original_correlation_id)
    return empty_story if events.empty?
    
    # Determine primary correlation ID
    primary_correlation_id = determine_primary_correlation_id(events)
    
    # Extract unique actors
    actors = extract_actors(events)
    
         # Categorize events by component
     components = categorize_events_by_component(events)
     
     # Generate story title
     story_title = generate_story_title(events)
     
     # Calculate duration
     timestamps = events.map(&:timestamp)
     duration = timestamps.any? ? ((timestamps.max - timestamps.min) * 1000).round(2) : 0
     
     {
       primary_correlation_id: primary_correlation_id,
       original_correlation_id: original_correlation_id,
       events: events.map { |event| { event: event, timestamp: event.timestamp } },
       total_events: events.length,
       first_event: events.first,
       last_event: events.last,
       duration: duration,
       actors: actors,
       components: components.keys,
       story_title: story_title
     }
  end
  
  # Return empty story structure
  def self.empty_story
         {
       primary_correlation_id: nil,
       original_correlation_id: nil,
       events: [],
       total_events: 0,
       first_event: nil,
       last_event: nil,
       duration: 0,
       actors: [],
       components: [],
       story_title: 'Empty Story'
     }
  end
  
  def self.group_events_by_primary_correlation(all_events)
    groups = {}
    
    all_events.each do |event|
      primary_correlation_id = extract_primary_correlation_id(event)
      
      # Only group if we have a valid primary_correlation_id
      # If no primary_correlation_id is found, skip this event (or use a special key)
      correlation_key = primary_correlation_id || "ungrouped_#{event.id}"
      
      groups[correlation_key] ||= []
      groups[correlation_key] << event
    end
    
    # After initial grouping by primary_correlation_id, look for cross-boundary links
    groups = merge_cross_boundary_stories(groups)
    
    # Sort each group by created_at to ensure chronological order
    groups.each do |key, events|
      groups[key] = events.sort_by(&:created_at)
    end
    
    groups
  end
  
  # Merge stories that are connected across boundaries (web -> job transitions)
  def self.merge_cross_boundary_stories(groups)
    merged_groups = {}
    processed_keys = Set.new
    
    groups.each do |key, events|
      next if processed_keys.include?(key)
      
      # Start with the current group
      merged_events = events.dup
      
      # Look for other groups that should be merged with this one
      groups.each do |other_key, other_events|
        next if other_key == key || processed_keys.include?(other_key)
        
        if stories_connected_by_correlation?(events, other_events)
          merged_events.concat(other_events)
          processed_keys.add(other_key)
        end
      end
      
      # Use the earliest correlation key as the merged key
      earliest_event = merged_events.min_by(&:created_at)
      earliest_correlation_id = extract_primary_correlation_id(earliest_event)
      merged_key = earliest_correlation_id || key
      
      merged_groups[merged_key] = merged_events
      processed_keys.add(key)
    end
    
    merged_groups
  end
  
  # Check if two story groups are connected by correlation relationships
  def self.stories_connected_by_correlation?(events1, events2)
    events1.each do |event1|
      events2.each do |event2|
        # Check for same request_id
        if same_request_id?(event1, event2)
          return true
        end
        
        # Check for parent-child flow relationships
        if parent_child_flow_relationship?(event1, event2)
          return true
        end
        
        # Check for flow_id relationships
        if flow_id_relationships?(event1, event2)
          return true
        end
      end
    end
    
    false
  end
  
  # Check if events have the same request_id
  def self.same_request_id?(event1, event2)
    req_id1 = event1.correlation&.dig('request_id') || event1.correlation_context&.dig('request_id')
    req_id2 = event2.correlation&.dig('request_id') || event2.correlation_context&.dig('request_id')
    
    req_id1.present? && req_id2.present? && req_id1 == req_id2
  end
  
  # Check for parent-child flow relationships
  def self.parent_child_flow_relationship?(event1, event2)
    # Check if event1's parent_flow_id matches event2's flow_id
    parent_flow1 = event1.correlation&.dig('parent_flow_id')
    flow_id2 = event2.correlation_context&.dig('flow_id')
    
    if parent_flow1.present? && flow_id2.present? && parent_flow1 == flow_id2
      return true
    end
    
    # Check the reverse relationship
    parent_flow2 = event2.correlation&.dig('parent_flow_id')
    flow_id1 = event1.correlation_context&.dig('flow_id')
    
    if parent_flow2.present? && flow_id1.present? && parent_flow2 == flow_id1
      return true
    end
    
    false
  end
  
  # Check for flow_id relationships between events
  def self.flow_id_relationships?(event1, event2)
    # Check if one event's flow_id appears in another's correlation chain
    flow_id1 = event1.correlation&.dig('flow_id') || event1.correlation_context&.dig('flow_id')
    flow_id2 = event2.correlation&.dig('flow_id') || event2.correlation_context&.dig('flow_id')
    
    # Check if they reference each other's flows
    parent_flow1 = event1.correlation&.dig('parent_flow_id')
    parent_flow2 = event2.correlation&.dig('parent_flow_id')
    
    (flow_id1.present? && parent_flow2.present? && flow_id1 == parent_flow2) ||
    (flow_id2.present? && parent_flow1.present? && flow_id2 == parent_flow1)
  end
  
  def self.get_depth(event)
    # Try correlation_context first
    if event.correlation_context.present?
      context = event.correlation_context
      context = JSON.parse(context) if context.is_a?(String)
      return context['depth'] if context.is_a?(Hash) && context['depth']
    end
    
    # Try correlation field
    if event.correlation.present?
      correlation = event.correlation
      correlation = JSON.parse(correlation) if correlation.is_a?(String)
      return correlation['depth'] if correlation.is_a?(Hash) && correlation['depth']
    end
    
    # Default to 0 if no depth found
    0
  rescue JSON::ParserError
    0
  end
  
  def self.create_story_from_events(events, primary_correlation_id, story_number)
    return nil if events.empty?
    
    # Sort events by depth and then by time
    sorted_events = events.sort_by { |e| [get_depth(e), e.created_at] }
    
    # The primary event is the one with depth 0 (or the first chronologically)
    primary_event = sorted_events.find { |e| get_depth(e) == 0 } || sorted_events.first
    
    # Determine story type based on the primary event
    story_type = case primary_event.event_type
                 when 'http.request'
                   'web'
                 when 'job.execution' 
                   'job'
                 when 'data.change'
                   'data.change'
                 else
                   'unknown'
                 end
    
    # Build component list from all event types in the story
    components = sorted_events.map(&:event_type).uniq
    
    # Calculate story duration
    duration = if sorted_events.count > 1
                 (sorted_events.last.created_at - sorted_events.first.created_at).abs
               else
                 0
               end
    
    {
      id: "story_#{story_number}",
      type: story_type,
      primary_correlation_id: primary_correlation_id,
      primary_event: primary_event,
      events: sorted_events,
      components: components,
      actor: primary_event.actor,
      started_at: sorted_events.first.created_at,
      ended_at: sorted_events.last.created_at,
      duration: duration,
      event_count: sorted_events.count
    }
  end
end 