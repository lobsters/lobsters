class NotifyCommentJob < ApplicationJob
  queue_as :default

  def perform(*comments)
    comments.each do |comment|
      deliver_comment_notifications(comment)
    end
  end

  def deliver_comment_notifications(comment)
    deliver_reply_notifications(comment)
    deliver_mention_notifications(comment)
  end

  def notify_once(user, comment)
    user.notifications.create(notifiable: comment).persisted?
  rescue ActiveRecord::RecordNotUnique
    false
  end

  def deliver_mention_notifications(comment)
    mentions = comment.comment.scan(/\B[@~]([\w-]+)/).flatten.uniq
    mentioned = User.active.where(username: mentions - [comment.user.username]).to_a

    hiding_users = HiddenStory.where(story: comment.story).pluck(:user_id)
    to_notify = mentioned.select { |u| notify_once(u, comment) }
      .reject { |u| hiding_users.include?(u.id) }

    to_notify.each do |u|
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
    hiding_users = HiddenStory.where(story: comment.story).pluck(:user_id)
    to_notify = users_following_thread(comment).select { |u| notify_once(u, comment) }
      .reject { |u| hiding_users.include?(u.id) }

    to_notify.each do |u|
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
  end
end
