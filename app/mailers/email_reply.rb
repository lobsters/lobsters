class EmailReply < ActionMailer::Base
  default :from => "#{Rails.application.name} " <<
    "<nobody@#{Rails.application.domain}>"

  def reply(comment, user)
    @comment = comment
    @user = user

    mail(
      :to => user.email,
      :subject =>  I18n.t('mailers.email_reply.replysubject', :appname => "#{Rails.application.name}", :author => "#{comment.user.username}", :story => "#{comment.story.title}")
    )
  end

  def mention(comment, user)
    @comment = comment
    @user = user

    mail(
      :to => user.email,
      :subject =>  I18n.t('mailers.email_reply.mentionsubject', :appname => "#{Rails.application.name}", :author => "#{comment.user.username}", :story => "#{comment.story.title}")
    )
  end
end
