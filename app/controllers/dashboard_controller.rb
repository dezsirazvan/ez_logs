class DashboardController < ApplicationController
  before_action :set_user_and_company
  helper_method :get_story_flows

  def index
    # Ensure we have a valid company
    company = current_user.company
    return redirect_to root_path, alert: "Company not found" unless company

    if current_user.admin?
      # Admin dashboard - show system-wide stats
      @event_stats = {
        total_events: Event.count,
        today_events: Event.where(timestamp: Date.current.beginning_of_day..Date.current.end_of_day).count,
        this_week_events: Event.where(timestamp: 1.week.ago..Time.current).count,
        active_sessions: User.where('last_sign_in_at > ?', 1.hour.ago).count,
        correlated_events: Event.where.not(correlation_id: [nil, '']).count,
        error_events: Event.where("action ILIKE ? OR action ILIKE ? OR action ILIKE ?", "%error%", "%exception%", "%fail%").count,
        total_users: User.count,
        total_companies: Company.count,
        total_api_keys: ApiKey.count
      }
      
      # Get recent events across all companies
      @recent_events = Event.includes(:company).order(timestamp: :desc).limit(10)
      
      # Get recent users across all companies
      @recent_users = User.includes(:role, :company).order(created_at: :desc).limit(5)
      
      # Get story flows across all companies
      @story_flows = get_system_story_flows
    else
      # Regular user dashboard - show company-specific stats
      @event_stats = {
        total_events: company.events.count,
        today_events: company.events.where(timestamp: Date.current.beginning_of_day..Date.current.end_of_day).count,
        this_week_events: company.events.where(timestamp: 1.week.ago..Time.current).count,
        active_sessions: company.users.where('last_sign_in_at > ?', 1.hour.ago).count,
        correlated_events: company.events.where.not(correlation_id: [nil, '']).count,
        error_events: company.events.where("action ILIKE ? OR action ILIKE ? OR action ILIKE ?", "%error%", "%exception%", "%fail%").count
      }
      
      # Get recent events for the company
      @recent_events = company.events.includes(:company).order(timestamp: :desc).limit(10)
      
      # Get recent users for the company
      @recent_users = company.users.includes(:role).order(created_at: :desc).limit(5)
      
      # Get story flows for the company
      @story_flows = get_story_flows
    end
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
    # Use the new StoryReconstructor to find complete stories
    complete_stories = StoryReconstructor.find_all_complete_stories(@company)
    
    @stories = complete_stories.map do |story|
      {
        correlation_id: story[:id],
        events: story[:events],
        event_count: story[:event_count],
        first_event: story[:events].first,
        last_event: story[:events].last,
        duration: story[:duration],
        actors: [actor_display_from_hash(story[:actor])].compact,
        event_types: story[:components],
        components: story[:components],
        story_title: "#{story[:type].capitalize} Story ##{story[:id].split('_').last}"
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
      total_count: complete_stories.length,
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
    
    # Find the story from all stories in the company
    complete_stories = StoryReconstructor.find_all_complete_stories(@company)
    complete_story = complete_stories.find { |story| story[:id] == @correlation_id }
    
    if complete_story.nil? || complete_story[:events].empty?
      redirect_to stories_path, alert: "Story not found"
      return
    end
    
    # Extract events from the complete story
    @events = complete_story[:events]
    
    @story_summary = {
      correlation_id: complete_story[:id],
      original_correlation_id: @correlation_id,
      event_count: complete_story[:event_count],
      first_event: complete_story[:events].first,
      last_event: complete_story[:events].last,
      duration: complete_story[:duration],
      actors: [actor_display_from_hash(complete_story[:actor])].compact,
      event_types: complete_story[:components],
      components: complete_story[:components],
      story_title: "#{complete_story[:type].capitalize} Story ##{complete_story[:id].split('_').last}"
    }
  end

  private

  def set_user_and_company
    @user = current_user
    @company = current_user.company
  end

  def get_story_flows
    # Use StoryReconstructor for dashboard summary
    complete_stories = StoryReconstructor.find_all_complete_stories(@company)
    
    complete_stories.first(5).map do |story|
      {
        correlation_id: story[:id],
        events: story[:events],
        event_count: story[:event_count],
        first_event: story[:events].first,
        last_event: story[:events].last,
        duration: story[:duration],
        actors: [actor_display_from_hash(story[:actor])].compact,
        event_types: story[:components]
      }
    end
  end

  def get_system_story_flows
    # Use StoryReconstructor for system-wide stories - get all companies
    all_companies = Company.all
    complete_stories = all_companies.flat_map { |company| StoryReconstructor.find_all_complete_stories(company) }
    
    complete_stories.first(5).map do |story|
      {
        correlation_id: story[:id],
        events: story[:events],
        event_count: story[:event_count],
        first_event: story[:events].first,
        last_event: story[:events].last,
        duration: story[:duration],
        actors: [actor_display_from_hash(story[:actor])].compact,
        event_types: story[:components]
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

  # Helper method to convert actor hash to display string
  def actor_display_from_hash(actor)
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
end
