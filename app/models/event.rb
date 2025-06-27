class Event < ApplicationRecord
  belongs_to :company

  # Universal event schema fields:
  # event_id, correlation_id, event_type, action, actor (JSON), subject (JSON), metadata, timestamp, correlation, correlation_context, payload, platform, validation_errors, timing, environment, impact

  validates :event_type, :action, :timestamp, :event_id, :correlation_id, presence: true
  validates :actor, presence: true

  # Scopes for filtering
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(timestamp: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(timestamp: start_date..end_date) }

  # Pagination support
  def self.page(page_number)
    page_number = page_number.to_i
    page_number = 1 if page_number < 1
    limit(20).offset((page_number - 1) * 20)
  end

  def self.per(per_page)
    limit(per_page)
  end

  # Add current_page method for pagination
  def self.current_page
    @current_page ||= 1
  end

  def self.current_page=(page)
    @current_page = page.to_i
  end

  # Helper: display name for event
  def display_name
    "#{event_type} - #{action}"
  end

  def actor_display
    return 'System' if actor.blank? || actor['type'].blank?
    type = actor['type'] || actor[:type]
    id = actor['id'] || actor[:id]
    email = actor['email'] || actor[:email]
    if email.present?
      "#{type.humanize} #{email}"
    else
      "#{type.humanize} #{id}"
    end
  end

  def subject_display
    return 'N/A' if subject.blank? || subject['type'].blank?
    type = subject['type'] || subject[:type]
    id = subject['id'] || subject[:id]
    "#{type.humanize} #{id}"
  end

  def metadata_summary
    return 'No additional data' if metadata.blank?
    if metadata.is_a?(Hash)
      metadata.keys.first(3).join(', ')
    else
      metadata.to_s.truncate(50)
    end
  end

  # Helper methods for new fields
  def timing_display
    return 'N/A' if timing.blank?
    if timing.is_a?(Hash)
      duration = timing['duration'] || timing[:duration]
      started_at = timing['started_at'] || timing[:started_at]
      completed_at = timing['completed_at'] || timing[:completed_at]
      
      if duration.present?
        "Duration: #{duration}ms"
      elsif started_at.present? && completed_at.present?
        start_time = Time.parse(started_at) rescue nil
        end_time = Time.parse(completed_at) rescue nil
        if start_time && end_time
          duration_ms = ((end_time - start_time) * 1000).round(2)
          "Duration: #{duration_ms}ms"
        else
          "Started: #{started_at}, Completed: #{completed_at}"
        end
      else
        timing.to_s.truncate(50)
      end
    else
      timing.to_s.truncate(50)
    end
  end

  def environment_display
    return 'N/A' if environment.blank?
    if environment.is_a?(Hash)
      env_name = environment['name'] || environment[:name] || environment['environment'] || environment[:environment]
      version = environment['version'] || environment[:version]
      region = environment['region'] || environment[:region]
      
      parts = []
      parts << env_name if env_name.present?
      parts << "v#{version}" if version.present?
      parts << region if region.present?
      
      parts.any? ? parts.join(' | ') : environment.keys.first(3).join(', ')
    else
      environment.to_s.truncate(50)
    end
  end

  def impact_display
    return 'N/A' if impact.blank?
    if impact.is_a?(Hash)
      severity = impact['severity'] || impact[:severity]
      affected_users = impact['affected_users'] || impact[:affected_users]
      affected_systems = impact['affected_systems'] || impact[:affected_systems]
      
      parts = []
      parts << "Severity: #{severity.humanize}" if severity.present?
      parts << "Users: #{affected_users}" if affected_users.present?
      parts << "Systems: #{affected_systems}" if affected_systems.present?
      
      parts.any? ? parts.join(' | ') : impact.keys.first(3).join(', ')
    else
      impact.to_s.truncate(50)
    end
  end

  # Accepts a UniversalEvent-style hash and creates an Event record
  def self.ingest_universal_event!(event_hash, company_id:)
    create!(company_id: company_id,
            event_id: event_hash[:event_id] || event_hash['event_id'],
            correlation_id: event_hash[:correlation_id] || event_hash['correlation_id'],
            event_type: event_hash[:event_type] || event_hash['event_type'],
            action: event_hash[:action] || event_hash['action'],
            actor: event_hash[:actor] || event_hash['actor'],
            subject: event_hash[:subject] || event_hash['subject'],
            metadata: event_hash[:metadata] || event_hash['metadata'],
            timestamp: event_hash[:timestamp] || event_hash['timestamp'] || Time.now.utc,
            correlation: event_hash[:correlation] || event_hash['correlation'],
            correlation_context: event_hash[:correlation_context] || event_hash['correlation_context'],
            payload: event_hash[:payload] || event_hash['payload'],
            platform: event_hash[:platform] || event_hash['platform'],
            timing: event_hash[:timing] || event_hash['timing'],
            environment: event_hash[:environment] || event_hash['environment'],
            impact: event_hash[:impact] || event_hash['impact'],
            validation_errors: event_hash[:validation_errors] || event_hash['validation_errors'] || [],
            source: event_hash[:source] || event_hash['source'],
            tags: event_hash[:tags] || event_hash['tags'])
  end

  # Returns all events in the same correlation (flow)
  def related_events
    return [] unless correlation_id.present?
    Event.where(company_id: company_id, correlation_id: correlation_id).order(:timestamp)
  end
end
