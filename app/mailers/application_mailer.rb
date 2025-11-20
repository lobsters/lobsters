# typed: false

class ApplicationMailer < ActionMailer::Base
  default from: "#{Rails.application.name} <nobody@#{Rails.application.domain}>"
  after_action :check_email_blocklist

  # https://github.com/rails/solid_queue#error-reporting-on-jobs
  ActionMailer::MailDeliveryJob.rescue_from(Exception) do |exception|
    Rails.error.report(exception)
    raise exception
  end

  def check_email_blocklist
    if EmailBlocklistValidation.email_on_blocklist?(mail.to[0])
      mail.perform_deliveries = false
    end
  end
end
