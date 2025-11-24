class NotifyCommentJob < ApplicationJob
  queue_as :default

  def perform(*comments)
    comments.each do |comment|
      deliver_comment_notifications(comment)
    end
  end

  def deliver_comment_notifications(comment)
    notified = deliver_reply_notifications(comment)
    deliver_mention_notifications(comment, notified)
  end

  def deliver_mention_notifications(comment, notified)
    mentions = comment.comment.scan(/\B[@~]([\w-]+)/).flatten.uniq
    # Remove username of author and anyone already notified about the reply.
    # If they have email_replies off, a reply that @mentions them will not generate a
    # mention email. email_replies trumps email_mentions to minimize unwanted emails.
    to_notify = mentions - [comment.user.username] - notified

    # every user gets a Notification, which may be filtered out from those views so that unhiding a
    # story reveals the notifications
    to_notify = User.active.where(username: to_notify)
    to_notify.find_each do |u|
      u.notifications.create(notifiable: comment)
    end

    # but there's no recalling an email or pushover, so sending those has to reflect story hiding
    not_hiding_users = to_notify.left_outer_joins(:hidings).where(hidden_stories: {id: nil})
    not_hiding_users.find_each do |u|
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
          message: comment.comment,
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

    to_notify = users_following_thread(comment)
    to_notify.each do |u|
      u.notifications.create(notifiable: comment)
      notified << u.username
    end

    hiding_users = HiddenStory.where(story: comment.story).pluck(:user_id)
    to_notify.each do |u|
      next if hiding_users.include? u.id

      if u.email_replies?
        begin
          EmailReplyMailer.reply(comment, u).deliver_now
        rescue => e
          # Rails.logger.error "error e-mailing #{u.email}: #{e}"
        end
      end

      if u.pushover_replies?
        u.pushover!(
          title: "#{Rails.application.name} reply from " \
            "#{comment.user.username} on #{comment.story.title}",
          message: comment.comment,
          url: Routes.comment_target_url(comment),
          url_title: "Reply to #{comment.user.username}"
        )
      end
    end

    notified
  end
end
