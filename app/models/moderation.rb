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

  include Token

  # A bug mistakenly recorded 10 users who doffed hats as moderators. To be able to say we don't
  # edit or remove modlog entries without adding a caveat, I've listed the tokens for those and the
  # frontend can explain that error when they appear. https://github.com/lobsters/lobsters/issues/1591
  BAD_DOFFING_ENTRIES = %w[
    moderation_01j6ax48wpfb4vas8qgv8vmg20
    moderation_01j79djrajfa5a56bbpmb6msde
    moderation_01j8myn90rey8axkbw0hntxfqe
    moderation_01j8n06kdrf5n92txy802evnz3
    moderation_01jajsjdd5fva8qdwgmc2es9gp
    moderation_01jat93zq7fgmr8dm6fc411g2c
    moderation_01jdgt4btvfvear3hphy79104f
    moderation_01jhzbz2mafxrsbmmr3trh760c
    moderation_01jmsbwaqxf2bbwws92cv8688k
    moderation_01jnywh2rxekqa61seqmk8z3f7
  ].freeze

  validates :action, presence: true, length: {maximum: 16_777_215}
  validates :reason, length: {maximum: 16_777_215}
  validates :is_from_suggestions, inclusion: {in: [true, false]}
  validate :one_foreign_key_present

  after_create :send_message_to_moderated
  after_create -> { ModActivity.create_for! self }

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
        "#{Routes.title_url(story)}) has been edited with the following " \
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
        "#{Routes.title_url comment.story}) has been moderated:\n" \
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
