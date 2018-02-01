ActionMailer::Base.smtp_settings = {
  :address => ENV.fetch("SMTP_HOST", "127.0.0.1"),
  :port => Integer(ENV.fetch("SMTP_PORT", 25)),
  :domain => Rails.application.domain,
  :enable_starttls_auto => ("true" == ENV["SMTP_STARTTLS_AUTO"]),
  :user_name => ENV.fetch("SMTP_USERNAME", ""),
  :password => ENV.fetch("SMTP_PASSWORD", ""),
}
