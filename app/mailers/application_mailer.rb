class ApplicationMailer < ActionMailer::Base
  default :from => "#{Rails.application.name} <nobody@#{Rails.application.domain}>"
end
