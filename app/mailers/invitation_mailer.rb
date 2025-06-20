class InvitationMailer < ApplicationMailer
  def invitation_email(invitation)
    @invitation = invitation
    @team = invitation.team
    @company = invitation.company
    @invited_by = invitation.invited_by
    @role = invitation.role
    
    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@team.name} on #{@company.name}"
    )
  end
end 