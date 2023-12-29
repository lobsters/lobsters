# typed: false

ActionMailer::Base.smtp_settings = {
  address: ENV.fetch("SMTP_HOST", "127.0.0.1"),
  port: Integer(ENV.fetch("SMTP_PORT", 25)),
  domain: "aqora-internal.io",
  user_name: ENV.fetch("SMTP_USERNAME", ""),
  password: ENV.fetch("SMTP_PASSWORD", ""),
  authentication:  'plain',
  enable_starttls: true,
  open_timeout:    5,
  read_timeout:    5
}