class EmailMessage < ActionMailer::Base
  default :from => "nobody@lobste.rs"

  def notify(message, user)
    @message = message
    @user = user

    mail(:to => user.email, :from => "Lobsters <nobody@lobste.rs>",
      :subject => "[Lobsters] Private Message from " <<
        "#{message.author.username}: #{message.subject}")
  end
end
