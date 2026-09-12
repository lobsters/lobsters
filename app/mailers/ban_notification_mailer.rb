# typed: false

class BanNotificationMailer < ApplicationMailer
  def notify(user, banner, reason)
    @banner = banner
    @reason = reason

    mail(
      from: "#{@banner.username} <reply-to@#{Rails.application.domain}>",
      reply_to: "#{@banner.username} <#{@banner.email}>",
      to: user.email,
      subject: "[#{Rails.application.name}] account #{user.username} banned"
    )
  end
end
