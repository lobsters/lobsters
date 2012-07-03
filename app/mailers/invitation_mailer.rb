class InvitationMailer < ActionMailer::Base
  def invitation(invitation)
    @invitation = invitation

    mail(:to => invitation.email,
      :from => "Lobsters Invitation <nobody@lobste.rs>",
      subject: "[Lobsters] Welcome to Lobsters")
  end
end
