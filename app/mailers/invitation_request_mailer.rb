class InvitationRequestMailer < ActionMailer::Base
  default :from => "#{Rails.application.name} " <<
    "<nobody@#{Rails.application.domain}>"

  def invitation_request(invitation_request)
    @invitation_request = invitation_request

    mail(
      :to => invitation_request.email,
      subject: I18n.t('mailers.invitation_request_mailer.subject', :appname => "#{Rails.application.name}")
    )
  end
end
