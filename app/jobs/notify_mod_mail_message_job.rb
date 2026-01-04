class NotifyModMailMessageJob < ApplicationJob
  queue_as :default

  def perform(*mod_mail_messages)
    mod_mail_messages.each do |mod_mail_message|
      mod_mail_message.mod_mail.recipients.each do |recipient|
        deliver_mod_mail_message_notifications(mod_mail_message, recipient) unless recipient == mod_mail_message.user
      end
    end
  end

  def deliver_mod_mail_message_notifications(mod_mail_message, recipient)
    read_at = mod_mail_message.notifications.find_by(user: recipient)&.read_at
    # TODO: Should this be a find or create by??
    recipient.notifications.create(notifiable: mod_mail_message, read_at: read_at)

    begin
      EmailModMailMessageMailer.notify(mod_mail_message, recipient).deliver_later
    rescue => e
      # Rails.logger.error "error e-mailing #{recipient.email}: #{e}"
    end

    return if Rails.env.development?

    if recipient.pushover_messages?
      recipient.pushover!(
        title: "#{Rails.application.name} message from " \
          "#{mod_mail_message.user.username}: #{mod_mail_message.mod_mail.subject}",
        message: mod_mail_message.plaintext_message,
        url: Routes.mod_mail_url(mod_mail_message.mod_mail),
        url_title: "Reply to #{mod_mail_message.user.username}"
      )
    end
  end
end
