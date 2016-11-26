class InvitationMailer < ActionMailer::Base
  default :from => "#{Rails.application.name} " <<
    "<nobody@#{Rails.application.domain}>"

  def invitation(invitation)
    @invitation = invitation

    mail(
      :to => invitation.email,
      subject: I18n.t('mailers.invitation_mailer.subject', :appname => "#{Rails.application.name}")
    )
  end
end
