class InvitationMailer < ActionMailer::Base
  default from: "nobody@lobste.rs"

  def invitation(root_url, invitation)
    @root_url = root_url
    @invitation = invitation

    mail(to: invitation.email, from: "Lobsters Invitation <nobody@lobste.rs>",
      subject: "[Lobsters] Welcome to Lobsters")
  end
end
