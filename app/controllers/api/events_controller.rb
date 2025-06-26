class Api::EventsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :authenticate_api_key!
  before_action :set_event, only: [:show]

  def index
    @events = build_api_events_query
    
    respond_to do |format|
      format.json { respond_with_json(@events) }
      format.csv { send_events_csv(@events) }
    end
  end

  def show
    respond_with_json(@event)
  end

  def create
    # Handle both Go agent batch format and single event format
    if go_agent_batch_request?
      handle_batch_create
    else
      handle_single_create
    end
  end

  private

  def go_agent_batch_request?
    # Check if request is from Go agent (JSON array in body)
    request.content_type&.include?('application/json') && 
    request.raw_post.strip.start_with?('[')
  end

  def handle_batch_create
    begin
      events_data = JSON.parse(request.raw_post)
      events_data = [events_data] unless events_data.is_a?(Array)
      
      created_events = []
      errors = []
      
      events_data.each_with_index do |event_data, index|
        event = current_api_key.company.events.build(batch_event_params(event_data))
        event.timestamp ||= Time.current
        event.source ||= 'go_agent'
        
        if event.save
          created_events << event
        else
          errors << { index: index, errors: event.errors.full_messages }
        end
      end
      
      if errors.empty?
        render json: {
          status: 'success',
          events_created: created_events.size,
          events: created_events.map { |e| { id: e.id, event_type: e.event_type, action: e.action } }
        }, status: :created
      else
        render json: {
          status: 'partial_success',
          events_created: created_events.size,
          events_failed: errors.size,
          errors: errors
        }, status: :multi_status
      end
      
    rescue JSON::ParserError => e
      render json: { 
        status: 'error', 
        message: 'Invalid JSON format',
        error: e.message 
      }, status: :bad_request
    rescue => e
      Rails.logger.error "Batch event creation error: #{e.message}"
      render json: { 
        status: 'error', 
        message: 'Internal server error' 
      }, status: :internal_server_error
    end
  end

  def handle_single_create
    @event = current_api_key.company.events.build(event_params)
    @event.timestamp ||= Time.current

    if @event.save
      render json: @event, status: :created
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  def batch_event_params(event_data)
    # Convert Go agent UniversalEvent format to Rails params
    {
      event_type: event_data['event_type'],
      action: event_data['action'],
      actor_type: event_data.dig('actor', 'type'),
      actor_id: event_data.dig('actor', 'id'),
      subject_type: event_data.dig('target', 'type') || event_data.dig('subject', 'type'),
      subject_id: event_data.dig('target', 'id') || event_data.dig('subject', 'id'),
      severity: event_data['severity'] || 'info',
      source: event_data['source'] || 'go_agent',
      tags: event_data['tags'],
      metadata: event_data['metadata'] || event_data.except('event_type', 'action', 'actor', 'target', 'subject', 'timestamp', 'severity', 'source', 'tags'),
      timestamp: parse_timestamp(event_data['timestamp'])
    }.compact
  end

  def parse_timestamp(timestamp_str)
    return Time.current if timestamp_str.blank?
    
    case timestamp_str
    when String
      Time.parse(timestamp_str) rescue Time.current
    when Time
      timestamp_str
    else
      Time.current
    end
  end

  def authenticate_api_key!
    token = request.headers['Authorization']&.gsub('Bearer ', '') ||
            request.headers['X-API-Key'] ||
            params[:api_key]
    
    @current_api_key = ApiKey.find_by(token: token, is_active: true)
    
    unless @current_api_key
      respond_with_error('Invalid or missing API key', status: :unauthorized)
      return
    end
  end

  def current_api_key
    @current_api_key
  end

  def set_event
    @event = current_api_key.company.events.find(params[:id])
  end

  def build_api_events_query
    events = current_api_key.company.events
                           .order(created_at: :desc)

    events = apply_api_event_filters(events)
    events.page(params[:page]).per(params[:per_page] || 25)
  end

  def apply_api_event_filters(events)
    events = events.where(event_type: params[:event_type]) if params[:event_type].present?
    events = events.where(actor_type: params[:actor_type]) if params[:actor_type].present?
    events = events.where(actor_id: params[:actor_id]) if params[:actor_id].present?
    events = events.where(severity: params[:severity]) if params[:severity].present?
    events = events.where(created_at: date_range_filter) if params[:date_range].present?
    
    if params[:search].present?
      events = events.where("event_type ILIKE ? OR action ILIKE ? OR metadata::text ILIKE ? OR actor_type ILIKE ? OR actor_id ILIKE ?", 
                           "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    events
  end

  def date_range_filter
    case params[:date_range]
    when '1h'
      1.hour.ago..Time.current
    when '24h'
      24.hours.ago..Time.current
    when '7d'
      7.days.ago..Time.current
    when '30d'
      30.days.ago..Time.current
    when '90d'
      90.days.ago..Time.current
    else
      7.days.ago..Time.current
    end
  end

  def send_events_csv(events)
    csv_data = generate_events_csv(events)
    filename = "events_#{Date.current.strftime('%Y-%m-%d')}.csv"
    
    send_data csv_data, 
              filename: filename,
              type: 'text/csv',
              disposition: 'attachment'
  end

  def generate_events_csv(events)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['Date', 'Event Type', 'Action', 'Actor Type', 'Actor ID', 'Subject Type', 'Subject ID', 'Severity', 'Source', 'Tags', 'Metadata']
      
      events.each do |event|
        csv << [
          event.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          event.event_type,
          event.action,
          event.actor_type || 'Unknown',
          event.actor_id || 'Unknown',
          event.subject_type || '',
          event.subject_id || '',
          event.severity || 'info',
          event.source || '',
          event.tags || '',
          event.metadata&.to_json || ''
        ]
      end
    end
  end

  def event_params
    params.require(:event).permit(:event_type, :action, :actor_type, :actor_id, :subject_type, :subject_id, :severity, :source, :tags, :metadata, :timestamp)
  end
end
