class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  validates :user_id, uniqueness: {scope: [:notifiable_type, :notifiable_id]}
  validates :notifiable_type, presence: true, length: {maximum: 255}

  scope :of_comments, -> { where(notifiable_type: "Comment") }
  scope :of_messages, -> { where(notifiable_type: "Message") }
  scope :of_mod_mail_messages, -> { where(notifiable_type: "ModMailMessage") }
  scope :read, -> { where.not(read_at: nil) }
  scope :unread, -> { where(read_at: nil) }

  before_validation on: :create do
    self.read_at = Time.current if !should_display?
  end

  include Token

  def should_display?
    case notifiable
    when Message
      should_display_message?
    when ModMailMessage
      true
    when Comment
      should_display_comment?
    end
  end

  def should_display_message?
    true
  end

  def should_display_comment?
    return false unless user_wants_notification?
    return false unless is_high_quality?

    true
  end

  private

  def user_wants_notification?
    comment = notifiable

    # Check if this is a mention notification
    if comment.comment.match?(Markdowner::USERNAME_MENTION)
      return user.inbox_mentions?
    end

    # For reply notifications, always show (user settings handled elsewhere)
    true
  end

  def is_high_quality?
    comment = notifiable
    story = comment.story
    parent_comment = comment.parent_comment
    replier_comment_ids = comment.user.comments.filter_map { |c| c.id if c.story_id == story.id }

    bad_properties = {
      bad_story: story.score <= story.flags,
      is_gone: comment.is_gone?,
      bad_comment: comment.score <= comment.flags,
      bad_parent_comment: parent_comment.nil? ? false : parent_comment.score <= parent_comment.flags || parent_comment.is_gone?,
      user_has_flagged_replier: !user.votes.filter { |v| v.story_id == story.id && v.vote == -1 && replier_comment_ids.include?(v.comment_id) }.empty?,
      user_has_hidden_story: !user.hidings.filter { |h| h.story_id == story.id }.empty?,
      user_has_filtered_tags_on_story: !(story.tags & user.tag_filter_tags).empty?
    }.compact_blank

    bad_properties.empty?
  end
end
