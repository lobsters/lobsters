class PasswordReset < ActionMailer::Base
  default from: "nobody@lobste.rs"

  def password_reset_link(user, ip)
    @user = user
    @ip = ip

    mail(to: user.email, from: "Lobsters <nobody@lobste.rs",
      subject: "[Lobsters] Reset your password")
  end
end
