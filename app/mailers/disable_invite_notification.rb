class DisableInviteNotification < ActionMailer::Base
  default :from => "#{Rails.application.name} " <<
    "<nobody@#{Rails.application.domain}>"

  def notify(user, mod, reason)
    @mod = mod
    @reason = reason

    mail(
      :from => "#{@mod.username} <nobody@#{Rails.application.domain}>",
      :replyto => "#{@mod.username} <#{@mod.email}>",
      :to => user.email,
      :subject => "[#{Rails.application.name}] Your invite privileges have been removed"
    )
  end
end
