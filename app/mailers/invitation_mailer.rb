# typed: false

class InvitationMailer < ApplicationMailer
  def invitation(invitation)
    @invitation = invitation

    mail(
      to: invitation.email,
      subject: "[#{Rails.application.name}] You are invited to join " <<
               Rails.application.name
    )
  end
end
