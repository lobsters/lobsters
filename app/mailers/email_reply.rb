class EmailReply < ActionMailer::Base
  default :from => "nobody@lobste.rs"

  def reply(comment, user)
    @comment = comment 
    @user = user

    mail(:to => user.email, :from => "Lobsters <nobody@lobste.rs>",
      :subject => "[Lobsters] Reply from #{comment.user.username} on " <<
      "#{comment.story.title}")
  end

  def mention(comment, user)
    @comment = comment 
    @user = user

    mail(:to => user.email, :from => "Lobsters <nobody@lobste.rs>",
      :subject => "[Lobsters] Mention from #{comment.user.username} on " <<
      "#{comment.story.title}")
  end
end
