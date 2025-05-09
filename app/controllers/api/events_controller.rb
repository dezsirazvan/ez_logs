class Api::EventsController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    events = Event.order(timestamp: :desc)

    render json: events
  end

  def create
    payload = JSON.parse(request.body.read)
    records = Array(payload).map do |event|
      Event.create!(event.slice(
        "event_id",
        "correlation_id",
        "event_type",
        "resource",
        "action",
        "actor",
        "metadata",
        "timestamp"
      ))
    end
    render json: { created: records.size }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
