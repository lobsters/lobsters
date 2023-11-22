# typed: false

class EmailReply < ApplicationMailer
  def reply(comment, user)
    @comment = comment
    @user = user

    @replied_to = "you"
    if @comment.parent_comment.nil?
      @replied_to = "your story"
    elsif @comment.parent_comment.user != @user
      @replied_to = @comment.parent_comment.user.username
    end

    mail(
      to: user.email,
      subject: "[#{Rails.application.name}] Reply from " \
                  "#{comment.user.username} on #{comment.story.title}"
    )
  end

  def mention(comment, user)
    @comment = comment
    @user = user

    mail(
      to: user.email,
      subject: "[#{Rails.application.name}] Mention from " \
                  "#{comment.user.username} on #{comment.story.title}"
    )
  end
end
