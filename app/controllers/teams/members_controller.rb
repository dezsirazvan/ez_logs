class Teams::MembersController < ApplicationController
  before_action :require_team_access!
  before_action :set_team
  before_action :set_member, only: [:remove, :update_role, :transfer_ownership]

  def index
    @members = @team.users.includes(:role).order(:first_name)
    @pending_invitations = @team.invitations.where(status: 'pending').includes(:role, :invited_by)
    @member_stats = build_member_stats
  end

  def invite
    return unless current_user.can_invite_members?

    invitation = @team.invite_user(
      params[:email],
      Role.find(params[:role_id]),
      current_user
    )

    if invitation
      flash[:success] = "Invitation sent to #{params[:email]}"
    else
      flash[:error] = "Failed to send invitation. User may already be a member or invited."
    end

    redirect_to teams_members_path
  end

  def remove
    return unless current_user.can_remove_members?
    return if @member == current_user

    if @team.remove_member(@member)
      flash[:success] = "#{@member.full_name} removed from team"
    else
      flash[:error] = "Failed to remove member from team"
    end

    redirect_to teams_members_path
  end

  def update_role
    return unless current_user.can_change_roles?

    new_role = Role.find(params[:role_id])
    
    if @member.update(role: new_role)
      flash[:success] = "Role updated for #{@member.full_name}"
    else
      flash[:error] = "Failed to update role"
    end

    redirect_to teams_members_path
  end

  def transfer_ownership
    return unless current_user.can_transfer_ownership?

    if @team.transfer_ownership(@member)
      flash[:success] = "Team ownership transferred to #{@member.full_name}"
    else
      flash[:error] = "Failed to transfer ownership"
    end

    redirect_to teams_members_path
  end

  def cancel_invitation
    return unless current_user.can_invite_members?

    invitation = @team.invitations.find(params[:invitation_id])
    
    if invitation.update(status: 'cancelled')
      flash[:success] = "Invitation cancelled"
    else
      flash[:error] = "Failed to cancel invitation"
    end

    redirect_to teams_members_path
  end

  private

  def set_team
    @team = current_user.team
  end

  def set_member
    @member = @team.users.find(params[:id])
  end

  def build_member_stats
    {
      total_members: @team.member_count,
      active_members: @team.active_member_count,
      pending_invitations: @team.pending_invitations_count,
      by_role: @team.users.joins(:role).group('roles.name').count
    }
  end
end 