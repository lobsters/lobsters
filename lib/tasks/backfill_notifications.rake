desc "backfills missing notifications for both comments and messages"
task backfill_notifications: :environment do
  read_at = Time.current

  Notification.transaction do
    started_at = Time.current
    Comment.includes(story: [:user], parent_comment: [:user]).find_each do |comment|
      if comment.parent_comment.nil?
        # top level comment
        if comment.story.user_is_following?
          Notification.create(
            user: comment.story.user,
            notifiable: comment,
            read_at: read_at
          )
        end
      else
        # child comment
        Notification.create(
          user: comment.parent_comment.user,
          notifiable: comment,
          read_at: read_at
        )
      end
    rescue ActiveRecord::RecordNotUnique
    end
    finished_at = Time.current
    puts "Created missing comment notifications, the time it took was #{finished_at - started_at} seconds"

    started_at = Time.current
    Message.includes(:recipient).find_each do |message|
      Notification.create(
        user: message.recipient,
        notifiable: message,
        read_at: nil
      )
    rescue ActiveRecord::RecordNotUnique
    end
    finished_at = Time.current
    puts "Created missing message notifications, the time it took was #{finished_at - started_at} seconds"
  end
end
