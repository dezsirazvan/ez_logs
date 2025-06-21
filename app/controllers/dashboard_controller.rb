class DashboardController < ApplicationController
  before_action :set_user_and_company
  helper_method :get_story_flows

  def index
    # Ensure we have a valid company
    company = current_user.company
    return redirect_to root_path, alert: "Company not found" unless company

    @event_stats = {
      total_events: company.events.count,
      today_events: company.events.where(timestamp: Date.current.beginning_of_day..Date.current.end_of_day).count,
      this_week_events: company.events.where(timestamp: 1.week.ago..Time.current).count,
      active_sessions: company.users.where('last_sign_in_at > ?', 1.hour.ago).count,
      correlated_events: company.events.where.not(correlation_id: [nil, '']).count,
      error_events: company.events.where("action ILIKE ? OR action ILIKE ? OR action ILIKE ?", "%error%", "%exception%", "%fail%").count
    }
    
    # Get recent events for the dashboard
    @recent_events = company.events.includes(:company).order(timestamp: :desc).limit(10)
    
    # Get recent users for the dashboard
    @recent_users = company.users.includes(:role).order(created_at: :desc).limit(5)
    
    # Get story flows (correlated events) for the dashboard
    @story_flows = get_story_flows
  rescue => e
    Rails.logger.error "Dashboard index error: #{e.message}"
    @event_stats = {
      total_events: 0,
      today_events: 0,
      this_week_events: 0,
      active_sessions: 0,
      correlated_events: 0,
      error_events: 0
    }
    @recent_events = []
    @recent_users = []
    @story_flows = []
  end

  def profile
    @user = current_user
    @recent_events = current_user.company.events.includes(:company).recent.limit(5)
  end

  def settings
    @user = current_user
    @company = current_user.company
    @recent_events = current_user.company.events.order(timestamp: :desc).limit(10)
  end

  def stories
    # Get all correlation IDs that have multiple events
    correlation_ids = @company.events
                              .where.not(correlation_id: [nil, ''])
                              .group(:correlation_id)
                              .having('COUNT(*) > 1')
                              .pluck(:correlation_id)
    
    @stories = correlation_ids.map do |correlation_id|
      events = @company.events.where(correlation_id: correlation_id).order(:timestamp)
      first_event = events.first
      last_event = events.last
      duration = first_event && last_event ? (last_event.timestamp - first_event.timestamp) : 0
      
      {
        correlation_id: correlation_id,
        events: events,
        event_count: events.count,
        first_event: first_event,
        last_event: last_event,
        duration: duration,
        actors: events.map { |e| e.actor_display }.uniq.compact,
        event_types: events.map(&:event_type).uniq.compact
      }
    end.sort_by { |story| -story[:event_count] }
    
    # Calculate totals before pagination
    total_events = @stories.sum { |s| s[:event_count] }
    total_actors = @stories.flat_map { |s| s[:actors] }.uniq.length
    avg_duration = @stories.any? ? @stories.sum { |s| s[:duration] } / @stories.length : 0
    
    # Implement pagination for the array
    page = (params[:page] || 1).to_i
    per_page = 12
    total_pages = (@stories.length.to_f / per_page).ceil
    
    @stories = @stories.slice((page - 1) * per_page, per_page) || []
    
    # Add pagination metadata
    @pagination = {
      current_page: page,
      total_pages: total_pages,
      total_count: correlation_ids.length,
      per_page: per_page,
      has_next: page < total_pages,
      has_prev: page > 1,
      total_events: total_events,
      total_actors: total_actors,
      avg_duration: avg_duration
    }
  end

  def story
    @correlation_id = params[:id]
    @events = @company.events.where(correlation_id: @correlation_id).order(:timestamp)
    
    if @events.empty?
      redirect_to stories_path, alert: "Story not found"
      return
    end
    
    first_event = @events.first
    last_event = @events.last
    duration = first_event && last_event ? (last_event.timestamp - first_event.timestamp) : nil
    
    @story_summary = {
      correlation_id: @correlation_id,
      event_count: @events.count,
      first_event: first_event,
      last_event: last_event,
      duration: duration,
      actors: @events.map { |e| e.actor_display }.uniq.compact,
      event_types: @events.map(&:event_type).uniq.compact
    }
  end

  private

  def set_user_and_company
    @user = current_user
    @company = current_user.company
  end

  def get_story_flows
    # Get correlation IDs with multiple events
    correlation_ids = @company.events
                              .where.not(correlation_id: [nil, ''])
                              .group(:correlation_id)
                              .having('COUNT(*) > 1')
                              .pluck(:correlation_id)
                              .first(5) # Limit to 5 for dashboard
    
    correlation_ids.map do |correlation_id|
      events = @company.events.where(correlation_id: correlation_id).order(:timestamp)
      first_event = events.first
      last_event = events.last
      duration = first_event && last_event ? (last_event.timestamp - first_event.timestamp) : 0
      
      {
        correlation_id: correlation_id,
        events: events,
        event_count: events.count,
        first_event: first_event,
        last_event: last_event,
        duration: duration,
        actors: events.map { |e| e.actor_display }.uniq.compact,
        event_types: events.map(&:event_type).uniq.compact
      }
    end
  end

  def apply_event_filters(events)
    events = events.where(event_type: @filters[:event_type]) if @filters[:event_type].present?
    
    # Apply date filter if specified
    if @filters[:date_range].present?
      date_filter = date_range_filter
      events = events.where(timestamp: date_filter) if date_filter
    end
    
    # Filter by actor type if specified
    if @filters[:actor_type].present?
      events = events.where(Arel.sql("actor->>'type' = ?"), @filters[:actor_type])
    end
    
    # Filter by correlation status if specified
    if @filters[:correlation_status].present?
      case @filters[:correlation_status]
      when 'with_correlation'
        events = events.where.not(correlation_id: [nil, ''])
      when 'without_correlation'
        events = events.where(correlation_id: [nil, ''])
      end
    end
    
    # Global search
    if @filters[:q].present?
      q = @filters[:q].downcase
      events = events.where(
        "LOWER(action) LIKE :q OR LOWER(metadata::text) LIKE :q OR LOWER(actor::text) LIKE :q OR LOWER(subject::text) LIKE :q OR LOWER(correlation_id) LIKE :q",
        q: "%#{q}%"
      )
    end
    
    events
  end

  def date_range_filter
    case @filters[:date_range]
    when '24h'
      24.hours.ago..Time.current
    when '7d'
      7.days.ago..Time.current
    when '30d'
      30.days.ago..Time.current
    when '90d'
      90.days.ago..Time.current
    else
      nil
    end
  end

  def build_event_query
    events = Event.includes(:company)
                  .where(company: current_user.company)
                  .order(timestamp: :desc)

    events = apply_event_filters(events)

    # Global search
    if @permitted_params[:q].present?
      q = @permitted_params[:q].downcase
      events = events.where(
        "LOWER(action) LIKE :q OR LOWER(metadata::text) LIKE :q OR LOWER(actor::text) LIKE :q OR LOWER(subject::text) LIKE :q OR LOWER(correlation_id) LIKE :q",
        q: "%#{q}%"
      )
    end

    # Handle pagination
    page = @permitted_params[:page].to_i
    page = 1 if page < 1
    per_page = 20
    
    # Set current page for the relation
    events.instance_variable_set(:@current_page, page)
    events.instance_variable_set(:@per_page, per_page)
    
    events.limit(per_page).offset((page - 1) * per_page)
  end

  def build_event_stats(events)
    base_query = events.except(:limit, :offset, :order)
    
    {
      total_events: base_query.count,
      today_events: base_query.where(timestamp: Date.current.beginning_of_day..Date.current.end_of_day).count,
      this_week_events: base_query.where(timestamp: 1.week.ago..Time.current).count,
      by_type: base_query.group(:event_type).count,
      active_sessions: current_user.company.users.where('last_sign_in_at > ?', 1.hour.ago).count
    }
  end

  def build_company_event_query
    Event.includes(:company)
         .where(company: current_user.company)
         .order(timestamp: :desc)
         .limit(10)
  end


  def send_event_csv(events)
    csv_data = generate_event_csv(events)
    filename = "events_#{Date.current.strftime('%Y-%m-%d')}.csv"
    
    send_data csv_data, 
              filename: filename,
              type: 'text/csv',
              disposition: 'attachment'
  end

  def generate_event_csv(events)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['Timestamp', 'Event ID', 'Correlation ID', 'Event Type', 'Action', 'Actor', 'Subject', 'Metadata', 'Source']
      
      events.each do |event|
        csv << [
          event.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
          event.event_id,
          event.correlation_id,
          event.event_type,
          event.action,
          event.actor_display,
          event.subject_display,
          event.metadata&.to_json || '',
          event.source || ''
        ]
      end
    end
  end
end
