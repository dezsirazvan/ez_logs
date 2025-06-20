class Teams::SettingsController < ApplicationController
  before_action :require_team_access!
  before_action :set_team

  def edit
    @team_settings = @team.settings_summary
    @available_roles = Role.all
  end

  def update
    if @team.update(team_params)
      flash[:success] = "Team settings updated successfully"
      log_activity('team_settings_updated', @team)
      redirect_to edit_teams_settings_path
    else
      flash[:error] = "Failed to update team settings"
      @team_settings = @team.settings_summary
      @available_roles = Role.all
      render :edit
    end
  end

  def update_settings
    new_settings = params[:settings] || {}
    
    if @team.update_settings(new_settings)
      flash[:success] = "Team settings updated successfully"
      log_activity('team_settings_updated', @team, { settings: new_settings })
    else
      flash[:error] = "Failed to update team settings"
    end

    redirect_to edit_teams_settings_path
  end

  def deactivate
    return unless current_user.team_owner?

    if @team.deactivate!
      flash[:success] = "Team deactivated successfully"
      log_activity('team_deactivated', @team)
    else
      flash[:error] = "Failed to deactivate team"
    end

    redirect_to edit_teams_settings_path
  end

  def activate
    return unless current_user.team_owner?

    if @team.activate!
      flash[:success] = "Team activated successfully"
      log_activity('team_activated', @team)
    else
      flash[:error] = "Failed to activate team"
    end

    redirect_to edit_teams_settings_path
  end

  private

  def set_team
    @team = current_user.team
  end

  def team_params
    params.require(:team).permit(:name, :description, :is_active)
  end
end 