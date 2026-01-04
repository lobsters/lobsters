# typed: false

class EmailModMailMessageMailer < ApplicationMailer
  def notify(mod_mail_message, user)
    @mod_mail_message = mod_mail_message
    @mod_mail = mod_mail_message.mod_mail
    @user = user

    mail(
      to: user.email,
      subject: "[#{Rails.application.name}] Mod Mail Message from " \
                  "#{mod_mail_message.user.username}: #{mod_mail_message.mod_mail.subject}"
    )
  end
end
