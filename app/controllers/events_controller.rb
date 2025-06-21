class EventsController < ApplicationController
  before_action :set_event, only: [:show, :destroy]

  def index
    page = params[:page].to_i
    page = 1 if page < 1
    per_page = 25
    base_query = build_events_query_base
    total_count = base_query.count
    total_pages = (total_count.to_f / per_page).ceil
    
    @events = base_query.limit(per_page).offset((page - 1) * per_page)
    
    # Add pagination methods to the events relation
    @events.define_singleton_method(:total_count) { total_count }
    @events.define_singleton_method(:current_page) { page }
    @events.define_singleton_method(:total_pages) { total_pages }
    @events.define_singleton_method(:limit_value) { per_page }
    @events.define_singleton_method(:previous_page) { page > 1 ? page - 1 : nil }
    @events.define_singleton_method(:next_page) { page < total_pages ? page + 1 : nil }

    @event_stats = build_event_stats(@events)
    
    # Fetch recent story flows
    recent_correlation_ids = apply_event_filters(current_user.company.events)
                              .where.not(correlation_id: nil)
                              .order(timestamp: :desc)
                              .limit(100) # Look at last 100 events to find recent flows
                              .pluck(:correlation_id)
                              .uniq
                              .sample(3)

    if recent_correlation_ids.any?
      @recent_story_flows = current_user.company.events
                                        .where(correlation_id: recent_correlation_ids)
                                        .order(timestamp: :asc)
                                        .group_by(&:correlation_id)
    else
      @recent_story_flows = {}
    end
    respond_to do |format|
      format.html
      format.json { respond_with_json(@events) }
      format.csv { send_events_csv(@events) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { respond_with_json(@event) }
    end
  end

  def search_suggestions
    query = params[:q].to_s.strip.downcase
    return render json: [] if query.length < 2

    suggestions = []
    
    # Parse field-specific searches
    if query.include?(':')
      field, value = query.split(':', 2)
      suggestions = get_field_suggestions(field, value)
    else
      # General search across all fields
      suggestions = get_general_suggestions(query)
    end

    render json: suggestions.uniq { |s| s[:value] }.first(10)
  end

  def destroy
    return unless current_user.can_access?('events', 'destroy')

    if @event.destroy
      flash[:success] = 'Event deleted successfully.'
    else
      flash[:error] = 'Failed to delete event.'
    end

    redirect_to events_path
  end

  private

  def set_event
    @event = current_user.company.events.find(params[:id])
  end

  def build_events_query_base
    events = current_user.company.events.order(timestamp: :desc)
    apply_event_filters(events)
  end

  def apply_event_filters(events)
    # Check if any user filters are explicitly set (not Rails controller actions)
    has_user_filters = params[:event_type].present? || 
                      params[:action_filter].present? || 
                      params[:date_range].present? || 
                      params[:actor_id].present? || 
                      params[:subject_id].present? || 
                      params[:search].present?
    
    # If no user filters are set, return all events (no filtering)
    return events unless has_user_filters
    
    # Only apply filters if they are explicitly set by the user
    events = events.where(event_type: params[:event_type]) if params[:event_type].present?
    events = events.where("action ILIKE ?", "%#{params[:action_filter]}%") if params[:action_filter].present?
    
    date_filter = date_range_filter
    events = events.where(timestamp: date_filter) if date_filter.present?
    
    # Filter by actor if specified
    if params[:actor_id].present?
      events = events.where(Arel.sql("actor->>'id' = ?"), params[:actor_id])
    end
    
    # Filter by subject if specified
    if params[:subject_id].present?
      events = events.where(Arel.sql("subject->>'id' = ?"), params[:subject_id])
    end
    
    if params[:search].present?
      events = events.where("event_type ILIKE ? OR action ILIKE ? OR metadata::text ILIKE ?", 
                           "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
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
      nil # No default filter - show all events
    end
  end

  def build_event_stats(events)
    # Create a fresh query without order, limit, offset for stats
    base_query = current_user.company.events
    
    # Check if any user filters are explicitly set (not Rails controller actions)
    has_user_filters = params[:event_type].present? || 
                      params[:action_filter].present? || 
                      params[:date_range].present? || 
                      params[:actor_id].present? || 
                      params[:subject_id].present? || 
                      params[:search].present?
    
    # Only apply filters if user filters are set
    base_query = apply_event_filters(base_query) if has_user_filters
    
    {
      total_events: base_query.count,
      today_events: base_query.where(timestamp: Date.current.beginning_of_day..Date.current.end_of_day).count,
      this_week_events: base_query.where(timestamp: 1.week.ago..Time.current).count,
      story_flows_count: base_query.where.not(correlation_id: nil).distinct.count(:correlation_id),
      by_type: base_query.group(:event_type).count,
      active_sessions: current_user.company.users.where('last_sign_in_at > ?', 1.hour.ago).count
    }
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

  def get_field_suggestions(field, value)
    suggestions = []
    
    case field
    when 'action'
      actions = current_user.company.events
                           .where("LOWER(action) LIKE ?", "%#{value}%")
                           .distinct
                           .pluck(:action)
                           .first(5)
      
      actions.each do |action|
        suggestions << {
          type: 'action',
          label: action,
          value: "action:#{action}"
        }
      end
      
    when 'type', 'event_type'
      event_types = current_user.company.events
                               .where("LOWER(event_type) LIKE ?", "%#{value}%")
                               .distinct
                               .pluck(:event_type)
                               .first(3)
      
      event_types.each do |event_type|
        suggestions << {
          type: 'event_type',
          label: event_type.humanize,
          value: "type:#{event_type}"
        }
      end
      
    when 'actor'
      actor_types = current_user.company.events
                               .where(Arel.sql("actor->>'type' ILIKE ?"), "%#{value}%")
                               .distinct
                               .pluck(Arel.sql("actor->>'type'"))
                               .compact
                               .first(3)
      
      actor_types.each do |actor_type|
        suggestions << {
          type: 'actor',
          label: "#{actor_type} (actor)",
          value: "actor:#{actor_type}"
        }
      end
      
    when 'subject'
      subject_types = current_user.company.events
                                 .where(Arel.sql("subject->>'type' ILIKE ?"), "%#{value}%")
                                 .distinct
                                 .pluck(Arel.sql("subject->>'type'"))
                                 .compact
                                 .first(3)
      
      subject_types.each do |subject_type|
        suggestions << {
          type: 'subject',
          label: "#{subject_type} (subject)",
          value: "subject:#{subject_type}"
        }
      end
      
    when 'correlation', 'corr'
      correlation_ids = current_user.company.events
                                   .where("LOWER(correlation_id) LIKE ?", "%#{value}%")
                                   .distinct
                                   .pluck(:correlation_id)
                                   .compact
                                   .first(3)
      
      correlation_ids.each do |correlation_id|
        suggestions << {
          type: 'correlation',
          label: correlation_id,
          value: correlation_id
        }
      end
    end
    
    suggestions
  end

  def get_general_suggestions(query)
    suggestions = []
    
    # Get unique actions
    actions = current_user.company.events
                         .where("LOWER(action) LIKE ?", "%#{query}%")
                         .distinct
                         .pluck(:action)
                         .first(5)
    
    actions.each do |action|
      suggestions << {
        type: 'action',
        label: action,
        value: action
      }
    end

    # Get unique event types
    event_types = current_user.company.events
                             .where("LOWER(event_type) LIKE ?", "%#{query}%")
                             .distinct
                             .pluck(:event_type)
                             .first(3)
    
    event_types.each do |event_type|
      suggestions << {
        type: 'event_type',
        label: event_type.humanize,
        value: event_type
      }
    end

    # Get unique actor types
    actor_types = current_user.company.events
                             .where(Arel.sql("actor->>'type' ILIKE ?"), "%#{query}%")
                             .distinct
                             .pluck(Arel.sql("actor->>'type'"))
                             .compact
                             .first(3)
    
    actor_types.each do |actor_type|
      suggestions << {
        type: 'actor',
        label: "#{actor_type} (actor)",
        value: "actor:#{actor_type}"
      }
    end

    # Get unique subject types
    subject_types = current_user.company.events
                               .where(Arel.sql("subject->>'type' ILIKE ?"), "%#{query}%")
                               .distinct
                               .pluck(Arel.sql("subject->>'type'"))
                               .compact
                               .first(3)
    
    subject_types.each do |subject_type|
      suggestions << {
        type: 'subject',
        label: "#{subject_type} (subject)",
        value: "subject:#{subject_type}"
      }
    end

    # Get correlation IDs
    correlation_ids = current_user.company.events
                                 .where("LOWER(correlation_id) LIKE ?", "%#{query}%")
                                 .distinct
                                 .pluck(:correlation_id)
                                 .compact
                                 .first(3)
    
    correlation_ids.each do |correlation_id|
      suggestions << {
        type: 'correlation',
        label: correlation_id,
        value: correlation_id
      }
    end

    suggestions
  end
end
