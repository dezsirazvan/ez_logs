class InvitationsController < ApplicationController
  before_action :set_invitation, only: [:accept, :decline]

  def accept
    if @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
      return
    end

    if @invitation.status != "pending"
      redirect_to root_path, alert: "This invitation has already been #{@invitation.status}."
      return
    end

    if user_signed_in?
      # User is already signed in, accept the invitation
      if @invitation.accept!(current_user)
        redirect_to dashboard_path, notice: "Welcome to #{@invitation.team.name}! You've been successfully added to the team."
      else
        redirect_to root_path, alert: "Unable to accept invitation. Please contact the team administrator."
      end
    else
      # User needs to sign up or sign in first
      session[:pending_invitation_token] = @invitation.token
      redirect_to new_user_registration_path, notice: "Please create an account or sign in to accept this invitation."
    end
  end

  def decline
    if @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
      return
    end

    if @invitation.status != "pending"
      redirect_to root_path, alert: "This invitation has already been #{@invitation.status}."
      return
    end

    if @invitation.decline!
      redirect_to root_path, notice: "You have declined the invitation to join #{@invitation.team.name}."
    else
      redirect_to root_path, alert: "Unable to decline invitation. Please contact the team administrator."
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
    
    unless @invitation
      redirect_to root_path, alert: "Invalid invitation link."
    end
  end
end 