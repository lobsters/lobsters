if ENV['MAILGUN_API_KEY']
  require 'mailgun-ruby'

  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    api_key: ENV['MAILGUN_API_KEY'],
    domain: Rails.application.domain,
  }
else
  ActionMailer::Base.smtp_settings = {
    :address => ENV.fetch("SMTP_HOST", "127.0.0.1"),
    :port => Integer(ENV.fetch("SMTP_PORT", 25)),
    :domain => Rails.application.domain,
    :enable_starttls_auto => (ENV["SMTP_STARTTLS_AUTO"] == "true"),
    :user_name => ENV.fetch("SMTP_USERNAME", ""),
    :password => ENV.fetch("SMTP_PASSWORD", ""),
  }
end
