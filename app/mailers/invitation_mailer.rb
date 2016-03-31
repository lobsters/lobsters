class InvitationMailer < ActionMailer::Base
  default :from => "#{DATABASE['mailer']['name']} " <<
    "<#{DATABASE['mailer']['email']}>"

  def invitation(invitation)
    @invitation = invitation

    mail(
      :to => invitation.email,
      subject: "[#{Rails.application.name}] You have been invited to " <<
        Rails.application.name
    )
  end
end
