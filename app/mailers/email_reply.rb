class EmailReply < ActionMailer::Base
  default :from => "#{Rails.application.name} <nobody@#{Rails.application.domain}>"

  def reply(comment, user)
    @comment = comment
    @user = user

    mail(
      :to => user.email,
      :subject => "[#{Rails.application.name}] Reply from " <<
                  "#{comment.user.username} on #{comment.story.title}"
    )
  end

  def mention(comment, user)
    @comment = comment
    @user = user

    mail(
      :to => user.email,
      :subject => "[#{Rails.application.name}] Mention from " <<
                  "#{comment.user.username} on #{comment.story.title}"
    )
  end
end
