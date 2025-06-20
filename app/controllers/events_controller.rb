class EventsController < ApplicationController
  before_action :set_event, only: [:show, :destroy]

  def index
    @events = build_events_query
    @event_stats = build_event_stats(@events)
    
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

  def build_events_query
    events = current_user.company.events
                         .order(timestamp: :desc)

    events = apply_event_filters(events)
    
    # Handle pagination
    page = params[:page].to_i
    page = 1 if page < 1
    per_page = 25
    
    events.limit(per_page).offset((page - 1) * per_page)
  end

  def apply_event_filters(events)
    events = events.where(event_type: params[:event_type]) if params[:event_type].present?
    events = events.where("action ILIKE ?", "%#{params[:action]}%") if params[:action].present?
    events = events.where(timestamp: date_range_filter) if params[:date_range].present?
    
    # Filter by actor if specified
    if params[:actor_id].present?
      events = events.where("actor->>'id' = ?", params[:actor_id])
    end
    
    # Filter by subject if specified
    if params[:subject_id].present?
      events = events.where("subject->>'id' = ?", params[:subject_id])
    end
    
    if params[:search].present?
      events = events.where("event_type ILIKE ? OR action ILIKE ? OR metadata::text ILIKE ? OR actor::text ILIKE ? OR subject::text ILIKE ?", 
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

  def build_event_stats(events)
    base_query = events.except(:limit, :offset)
    
    {
      total_events: base_query.count,
      today_events: base_query.where(timestamp: Date.current.beginning_of_day..Date.current.end_of_day).count,
      this_week_events: base_query.where(timestamp: 1.week.ago..Time.current).count,
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
                               .where("actor->>'type' ILIKE ?", "%#{value}%")
                               .distinct
                               .pluck("actor->>'type'")
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
                                 .where("subject->>'type' ILIKE ?", "%#{value}%")
                                 .distinct
                                 .pluck("subject->>'type'")
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
                             .where("actor->>'type' ILIKE ?", "%#{query}%")
                             .distinct
                             .pluck("actor->>'type'")
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
                               .where("subject->>'type' ILIKE ?", "%#{query}%")
                               .distinct
                               .pluck("subject->>'type'")
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
