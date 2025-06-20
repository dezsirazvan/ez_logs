class DashboardController < ApplicationController
  before_action :set_user_and_company

  def index
    @event_stats = {
      total_events: current_user.company.events.count,
      today_events: current_user.company.events.where(timestamp: Date.current.beginning_of_day..Date.current.end_of_day).count,
      this_week_events: current_user.company.events.where(timestamp: 1.week.ago..Time.current).count,
      active_sessions: current_user.company.users.where('last_sign_in_at > ?', 1.hour.ago).count
    }
    @recent_events = current_user.company.events.includes(:company).recent.limit(10)
  end

  def profile
    @recent_events = current_user.company.events.includes(:company).recent.limit(5)
    @api_key_summary = current_user.api_key_summary
    @team_summary = current_user.team_summary
  end

  def settings
    @user = current_user
    @company = current_user.company
    @recent_events = current_user.company.events.order(timestamp: :desc).limit(10)
  end

  def events
    # Permit parameters for filtering and pagination
    @permitted_params = params.permit(:q, :event_type, :date_range, :actor_id, :subject_id, :page, :commit, :actor_type, :correlation_status)
    
    @events = build_event_query
    @event_stats = build_event_stats(@events)
    
    # Convert to hash for easier manipulation in views
    @filters = @permitted_params.to_h
    
    respond_to do |format|
      format.html
      format.csv { send_event_csv(@events) }
    end
  end

  def team
    @teams = current_user.company.teams.includes(:users, :owner)
    @company_users = current_user.company.users.includes(:role, :team).order(:first_name)
    @recent_company_events = build_company_event_query
    @team_stats = build_team_stats
  end

  private

  def set_user_and_company
    @user = current_user
    @company = current_user.company
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

  def apply_event_filters(events)
    events = events.where(event_type: @permitted_params[:event_type]) if @permitted_params[:event_type].present?
    
    # Only apply date filter if a specific range is selected
    if @permitted_params[:date_range].present?
      date_filter = date_range_filter
      events = events.where(timestamp: date_filter) if date_filter
    end
    
    # Filter by actor type if specified
    if @permitted_params[:actor_type].present?
      events = events.where("actor->>'type' = ?", @permitted_params[:actor_type])
    end
    
    # Filter by correlation status if specified
    if @permitted_params[:correlation_status].present?
      case @permitted_params[:correlation_status]
      when 'with_correlation'
        events = events.where.not(correlation_id: [nil, ''])
      when 'without_correlation'
        events = events.where(correlation_id: [nil, ''])
      end
    end
    
    # Filter by actor if specified
    if @permitted_params[:actor_id].present?
      events = events.where("actor->>'id' = ?", @permitted_params[:actor_id])
    end
    
    # Filter by subject if specified
    if @permitted_params[:subject_id].present?
      events = events.where("subject->>'id' = ?", @permitted_params[:subject_id])
    end
    
    events
  end

  def date_range_filter
    case @permitted_params[:date_range]
    when '24h'
      24.hours.ago..Time.current
    when '7d'
      7.days.ago..Time.current
    when '30d'
      30.days.ago..Time.current
    when '90d'
      90.days.ago..Time.current
    else
      nil # No filter when no date range is specified
    end
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

  def build_team_stats
    {
      total_events: current_user.company.events.count,
      total_alerts: current_user.company.alerts.count,
      events_this_month: current_user.company.events.where(timestamp: 1.month.ago..Time.current).count,
      total_teams: current_user.company.teams.count,
      total_members: current_user.company.users.count
    }
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
