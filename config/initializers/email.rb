# typed: false

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  address: ENV.fetch("SMTP_HOST", "127.0.0.1"),
  port: Integer(ENV.fetch("SMTP_PORT", 25)),
  domain: Rails.application.domain,
  user_name: ENV.fetch("SMTP_USERNAME", ""),
  password: ENV.fetch("SMTP_PASSWORD", ""),
  authentication:  'plain',
  enable_starttls: true,
  open_timeout:    5,
  read_timeout:    5
}