# typed: false

class BanNotificationMailer < ApplicationMailer
  def notify(user, banner, reason)
    @banner = banner
    @reason = reason

    mail(
      from: "#{@banner.username} <reply-to@#{Rails.application.domain}>",
      reply_to: "#{@banner.username} <#{@banner.email}>",
      to: user.email,
      subject: "[#{Rails.application.name}] You have been banned"
    )
  end
end
