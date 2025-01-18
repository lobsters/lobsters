# typed: false

class Moderation < ApplicationRecord
  belongs_to :moderator,
    class_name: "User",
    foreign_key: "moderator_user_id",
    inverse_of: :moderations,
    optional: true
  belongs_to :comment,
    optional: true
  belongs_to :domain,
    optional: true
  belongs_to :origin,
    optional: true
  belongs_to :story,
    optional: true
  belongs_to :tag,
    optional: true
  belongs_to :user,
    optional: true
  belongs_to :category,
    optional: true

  scope :for_user, ->(user) {
    left_outer_joins(:story, :comment)
      .includes(:moderator, comment: [:user, :story], story: :user)
      .where("
        moderations.user_id = ? OR
        stories.user_id = ? OR
        comments.user_id = ?", user, user, user)
      .order(id: :desc)
      .limit(20)
  }
  scope :for_story, ->(story) {
    left_outer_joins(:story, :comment)
      .includes(:moderator, comment: [:user, :story], story: :user)
      .where("
        moderations.user_id = ? OR
        stories.user_id = ? OR
        comments.user_id = ? OR
        moderations.story_id = ? OR
        comments.story_id = ? ",
        story.user, story.user, story.user, story, story)
      .order(id: :desc)
      .limit(20)
  }

  validates :action, :reason, length: {maximum: 16_777_215}
  validates :is_from_suggestions, inclusion: {in: [true, false]}
  validate :one_foreign_key_present

  after_create :send_message_to_moderated

  def send_message_to_moderated
    m = Message.new
    m.author_user_id = moderator_user_id

    # mark as deleted by author so they don't fill up moderator message boxes
    m.deleted_by_author = true

    if story
      m.recipient_user_id = story.user_id
      m.subject = "Your story has been edited by " +
        (is_from_suggestions? ? "user suggestions" : "a moderator")
      m.body = "Your story [#{story.title}](" \
        "#{story.comments_url}) has been edited with the following " \
        "changes:\n" \
        "\n" \
        "> *#{action}*\n"

      if reason.present?
        m.body << "\n" \
          "The reason given:\n" \
          "\n" \
          "> *#{reason}*\n" \
          "\n" \
          "Maybe the guidelines on topicality are useful: https://lobste.rs/about#topicality"
      end

    elsif comment
      m.recipient_user_id = comment.user_id
      m.subject = "Your comment has been moderated"
      m.body = "Your comment on [#{comment.story.title}](" \
        "#{comment.story.comments_url}) has been moderated:\n" \
        "\n" <<
        comment.comment.split("\n").map { |l| "> #{l}" }.join("\n")

      if reason.present?
        m.body << "\n" \
          "The reason given:\n" \
          "\n" \
          "> *#{reason}*\n"
      end

    else
      # no point in alerting deleted users, they can't login to read it
      return
    end

    return if m.recipient_user_id == m.author_user_id

    m.body << "\n" \
      "*This is an automated message.*"

    m.save!
  end

  protected

  def one_foreign_key_present
    fks = [comment_id, domain_id, origin_id, story_id, category_id, tag_id, user_id].compact.length
    errors.add(:base, "moderation should be linked to only one object") if fks != 1
  end
end
