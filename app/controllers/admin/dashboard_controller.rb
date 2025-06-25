class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @company = current_user.company
    @recent_activities = Activity.includes(:user).order(created_at: :desc).limit(10)
    @system_stats = build_system_stats
  end

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to dashboard_path, alert: "Access denied. Admin privileges required."
    end
  end

  def build_system_stats
    {
      total_users: User.count,
      active_users: User.active.count,
      locked_users: User.locked.count,
      total_events: Event.count,
      total_alerts: Alert.count,
      total_api_keys: ApiKey.count
    }
  end
end
