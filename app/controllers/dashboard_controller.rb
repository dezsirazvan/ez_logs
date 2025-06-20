class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_user

  def index
    @recent_events = Event.includes(:user, :team).order(created_at: :desc).limit(10)
    @recent_alerts = Alert.includes(:user, :team).order(created_at: :desc).limit(5)
    @user_stats = current_user_stats
    @team_stats = current_user.team&.analytics_summary || {}
    @system_stats = system_stats
  end

  def profile
    @user = current_user
    @recent_activity = AuditLog.where(user: @user)
                              .order(created_at: :desc)
                              .limit(20)
  end

  def settings
    @user = current_user
    @api_keys = @user.api_keys.active
  end

  def activity
    @activities = AuditLog.includes(:user)
                         .where(user: current_user)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(25)
  end

  def team
    @team = current_user.team
    return redirect_to dashboard_path, alert: "You are not part of a team." unless @team

    @team_members = @team.users.includes(:role).order(:first_name)
    @recent_team_activity = AuditLog.where(user: @team_members)
                                   .order(created_at: :desc)
                                   .limit(20)
    @team_stats = @team.analytics_summary
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def current_user_stats
    {
      total_events: Event.where(user: current_user).count,
      total_alerts: Alert.where(user: current_user).count,
      events_this_month: Event.where(user: current_user, created_at: 1.month.ago..Time.current).count,
      alerts_this_month: Alert.where(user: current_user, created_at: 1.month.ago..Time.current).count,
      last_login: current_user.last_login_at,
      login_count: current_user.login_count || 0
    }
  end

  def system_stats
    {
      total_users: User.count,
      total_teams: Team.count,
      total_events: Event.count,
      total_alerts: Alert.count,
      active_sessions: UserSession.active.count
    }
  end
end
