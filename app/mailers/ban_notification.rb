class BanNotification < ActionMailer::Base
  default :from => "#{DATABASE['mailer']['name']} " <<
    "<#{DATABASE['mailer']['email']}>"

  def notify(user, banner, reason)
    @banner = banner
    @reason = reason

    mail(
      :from => "#{@banner.username} <nobody@#{Rails.application.domain}>",
      :replyto => "#{@banner.username} <#{@banner.email}>",
      :to => user.email,
      :subject => "[#{Rails.application.name}] You have been banned"
    )
  end
end
