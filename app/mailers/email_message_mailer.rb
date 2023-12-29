# typed: false

class EmailMessageMailer < ApplicationMailer
  def notify(message, user)
    @message = message
    @user = user

    mail(
      to: user.email,
      subject: "[#{Rails.application.name}] Private Message from " \
                  "#{message.author_username}: #{message.subject}"
    )
  end
end
