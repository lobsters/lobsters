# typed: false

class ApplicationMailer < ActionMailer::Base
  include EmailBlocklistHelper

  default from: "#{Rails.application.name} <nobody@#{Rails.application.domain}>"
  after_action :check_blocklist

  def check_blocklist
    if email_on_blocklist?(mail.to[0])
      mail.perform_deliveries = false
    end
  end
end
