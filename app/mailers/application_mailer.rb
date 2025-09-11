# typed: false

class ApplicationMailer < ActionMailer::Base
  default from: "#{Rails.application.name} <nobody@#{Rails.application.domain}>"
  after_action :check_email_blocklist

  def check_email_blocklist
    if EmailBlocklistValidation.email_on_blocklist?(mail.to[0])
      mail.perform_deliveries = false
    end
  end
end
