ActionMailer::Base.smtp_settings = {
  :address => "127.0.0.1",
  :port => 25,
  :domain => Rails.application.domain,
  :enable_starttls_auto => false,
}
