# typed: false

class PasswordResetMailer < ApplicationMailer
  def password_reset_link(user, ip)
    @user = user
    @ip = ip

    mail(
      to: user.email,
      subject: "[#{Rails.application.name}] Reset your password"
    )
  end
end
