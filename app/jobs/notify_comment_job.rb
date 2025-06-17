class NotifyCommentJob < ApplicationJob
  queue_as :default

  def perform(*args)
    args.each do |arg|
      deliver_comment_notifications(arg)
    end
  end

  def deliver_comment_notifications(comment)
    notified = deliver_reply_notifications(comment)
    deliver_mention_notifications(comment, notified)
  end

  def deliver_mention_notifications(comment, notified)
    to_notify = comment.plaintext_comment.scan(/\B[@~]([\w\-]+)/).flatten.uniq - notified - [comment.user.username]
    User.active.where(username: to_notify).find_each do |u|
      if u.email_mentions?
        begin
          EmailReplyMailer.mention(comment, u).deliver_now
        rescue => e
          # Rails.logger.error "error e-mailing #{u.email}: #{e}"
        end
      end

      if u.pushover_mentions?
        u.pushover!(
          title: "#{Rails.application.name} mention by " \
            "#{comment.user.username} on #{comment.story.title}",
          message: comment.plaintext_comment,
          url: Routes.comment_target_url(comment),
          url_title: "Reply to #{comment.user.username}"
        )
      end
    end
  end

  def users_following_thread(comment)
    users_following_thread = Set.new
    if comment.user.id != comment.story.user.id && comment.story.user_is_following
      users_following_thread << comment.story.user
    end

    if comment.parent_comment_id &&
        (u = comment.parent_comment.try(:user)) &&
        u.id != comment.user.id &&
        u.is_active?
      users_following_thread << u
    end

    users_following_thread
  end

  def deliver_reply_notifications(comment)
    notified = []

    users_following_thread(comment).each do |u|
      if u.email_replies?
        begin
          EmailReplyMailer.reply(comment, u).deliver_now
          notified << u.username
        rescue => e
          # Rails.logger.error "error e-mailing #{u.email}: #{e}"
        end
      end

      if u.pushover_replies?
        u.pushover!(
          title: "#{Rails.application.name} reply from " \
            "#{comment.user.username} on #{comment.story.title}",
          message: comment.plaintext_comment,
          url: Routes.comment_target_url(comment),
          url_title: "Reply to #{comment.user.username}"
        )
        notified << u.username
      end
    end

    notified
  end
end
