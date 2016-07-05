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
      m.subject = I18n.t('models.moderation.storyeditedby') <<
        (self.is_from_suggestions? ? I18n.t('models.moderation.usersuggestions') : I18n.t('models.moderation.amoderator'))
      m.body = I18n.t('models.moderation.storyeditedfor', :title=> "#{self.story.title}", :url=>  "#{self.story.comments_url}") <<
        "\n" <<
        "> *#{self.action}*\n"

      if self.reason.present?
        m.body << "\n" <<
          I18n.t('models.moderation.reasongiven') <<
          "\n" <<
          "> *#{self.reason}*\n"
      end

    elsif self.comment
      m.recipient_user_id = self.comment.user_id
      m.subject = I18n.t('models.moderation.commentmoderated')
      m.body = I18n.t('models.moderation.commentmoderatedwhy', :title=> "#{self.comment.story.title}", :url=> "#{self.comment.story.comments_url}") <<
        "\n" <<
        "> *#{self.comment.comment}*\n"

      if self.reason.present?
        m.body << "\n" <<
          I18n.t('models.moderation.reasongiven') <<
          "\n" <<
          "> *#{self.reason}*\n"
      end

    else
      # no point in alerting deleted users, they can't login to read it
      return
    end

    m.body << "\n" <<
      I18n.t('models.moderation.automatedmessage')

    m.save
  end
end
