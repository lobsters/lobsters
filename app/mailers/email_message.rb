class EmailMessage < ActionMailer::Base
  default :from => "#{Rails.application.name} " <<
    "<nobody@#{Rails.application.domain}>"

  def notify(message, user)
    @message = message
    @user = user

    mail(
      :to => user.email,
      :subject => I18n.t('mailers.email_message.subject', :appname => "#{Rails.application.name}", :author => "#{message.author_username}", :subject => "#{message.subject}")
    )
  end
end
