class Moderation < ActiveRecord::Base
  belongs_to :moderator,
    :class_name => "User",
    :foreign_key => "moderator_user_id"
  belongs_to :story
  belongs_to :comment
  belongs_to :user

  after_create :send_message_to_moderated

  def send_message_to_moderated
    m = Message.new
    m.author_user_id = self.moderator_user_id

    # mark as deleted by author so they don't fill up moderator message boxes
    m.deleted_by_author = true

    if self.story
      m.recipient_user_id = self.story.user_id
      m.subject = "Your story has been edited by a moderator"
      m.body = "Your story [#{self.story.title}](" <<
        "#{self.story.comments_url}) has been edited by a moderator with " <<
        "the following changes:\n" <<
        "\n" <<
        "> *#{self.action}*\n"

      if self.reason.present?
        m.body << "\n" <<
          "The reason given:\n" <<
          "\n" <<
          "> *#{self.reason}*\n"
      end

    elsif self.comment
      m.recipient_user_id = self.comment.user_id
      m.subject = "Your comment has been moderated"
      m.body = "Your comment on [#{self.comment.story.title}](" <<
        "#{self.comment.story.comments_url}) has been moderated:\n" <<
        "\n" <<
        "> *#{self.comment.comment}*\n"

      if self.reason.present?
        m.body << "\n" <<
          "The reason given:\n" <<
          "\n" <<
          "> *#{self.reason}*\n"
      end

    else
      # no point in alerting deleted users, they can't login to read it
      return
    end

    m.body << "\n" <<
      "*This is an automated message.*"

    m.save
  end
end
