class NotifyMessageJob < ApplicationJob
  queue_as :default

  def perform(*args)
    args.each do |arg|
      deliver_message_notifications(arg)
    end
  end

  def deliver_message_notifications(message)
    if message.recipient.email_messages?
      begin
        EmailMessageMailer.notify(message, message.recipient).deliver_now
      rescue => e
        # Rails.logger.error "error e-mailing #{recipient.email}: #{e}"
      end
    end

    return if Rails.env.development?

    if message.recipient.pushover_messages?
      message.recipient.pushover!(
        title: "#{Rails.application.name} message from " \
          "#{message.author_username}: #{message.subject}",
        message: message.plaintext_body,
        url: Routes.message_url(message),
        url_title: (message.author ? "Reply to #{message.author_username}" :
          "View message")
      )
    end
  end
end
