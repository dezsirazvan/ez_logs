class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  def index
    @teams = current_user.company.teams.includes(:users, :owner).order(:name)
  end

  def show
    @available_users = current_user.company.users.where.not(id: @team.user_ids).includes(:role)
  end

  def new
    @team = current_user.company.teams.build
  end

  def create
    @team = current_user.company.teams.build(team_params)
    @team.owner = current_user
    
    if @team.save
      redirect_to team_path(@team), notice: 'Team was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @team.update(team_params)
      redirect_to team_path(@team), notice: 'Team was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @team.can_be_deleted?
      @team.destroy
      redirect_to teams_path, notice: 'Team was successfully deleted.'
    else
      redirect_to team_path(@team), alert: 'Cannot delete team with members or active projects.'
    end
  end

  def add_member
    @team = current_user.company.teams.find(params[:id])
    user = current_user.company.users.find(params[:user_id])
    role = Role.find(params[:role_id]) if params[:role_id].present?
    
    @team.users << user
    user.update(role: role) if role
    
    redirect_to team_path(@team), notice: "#{user.full_name} was added to the team."
  rescue ActiveRecord::RecordNotFound
    redirect_to team_path(@team), alert: 'User or role not found.'
  end

  def remove_member
    @team = current_user.company.teams.find(params[:id])
    user = @team.users.find(params[:user_id])
    
    if user == @team.owner
      redirect_to team_path(@team), alert: 'Cannot remove team owner.'
    else
      @team.users.delete(user)
      redirect_to team_path(@team), notice: "#{user.full_name} was removed from the team."
    end
  end

  private

  def set_team
    @team = current_user.company.teams.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :description, :is_active)
  end
end 