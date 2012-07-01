class PasswordReset < ActionMailer::Base
  default from: "nobody@lobste.rs"

  def password_reset_link(root_url, user, ip)
    @root_url = root_url
    @user = user
    @ip = ip

    mail(to: user.email, from: "Lobsters <nobody@lobste.rs>",
      subject: "[Lobsters] Reset your password")
  end
end
