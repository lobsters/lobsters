ActionMailer::Base.smtp_settings = {
  :address => "smtp.office365.com",
  :port => 587,
  :domain => Rails.application.domain,
  :enable_starttls_auto => true,
  :user_name => ENV['SMTP_USERNAME'],
  :password => ENV['SMTP_PASSWORD'],
  :authentication => :login
}
