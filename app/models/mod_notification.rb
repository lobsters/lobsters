class ModNotification < ApplicationRecord
  REASONS = %w[flagged hotspot].freeze

  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  validates :reason, inclusion: {in: REASONS}
  validates :notifiable_type, presence: true, length: {maximum: 255}
  validates :user_id, uniqueness: {scope: [:notifiable_type, :notifiable_id, :reason]}

  scope :flagged, -> { where(reason: "flagged") }
  scope :hotspot, -> { where(reason: "hotspot") }
  scope :of_stories, -> { where(notifiable_type: "Story") }
  scope :of_comments, -> { where(notifiable_type: "Comment") }
  scope :read, -> { where.not(read_at: nil) }
  scope :unread, -> { where(read_at: nil) }

  before_validation on: :create do
    self.read_at = Time.current if !should_display?
  end

  include Token

  def should_display?
    case notifiable
    when Story
      notifiable.merged_story_id.nil?
    when Comment
      # hotspots drop out once the comment is moderated or flagged: those are covered elsewhere
      reason == "flagged" || (!notifiable.is_moderated? && !Comment.mod_flagged.exists?(notifiable_id))
    else
      false
    end
  end

  # These are called after a vote or a reindex; each is idempotent and checks the current database
  # state, so callers don't need to know whether a threshold was crossed.
  def self.notice_story(story)
    return unless Story.unmerged.where("flags > 1").exists?(story.id)
    notice!(story, "flagged")
  end

  def self.notice_comment(comment)
    return unless Comment.mod_flagged.exists?(comment.id)
    notice!(comment, "flagged")
  end

  def self.notice_hotspot(comment)
    return unless HotspotDoc.hits.exists?(comment_id: comment.id)
    return if comment.is_moderated? || Comment.mod_flagged.exists?(comment.id)
    notice!(comment, "hotspot")
  end

  # For after bulk writes to HotspotDoc, which skip the per-comment hooks.
  def self.notice_hotspots!
    Comment.not_moderated
      .where.not(id: Comment.mod_flagged.select(:id))
      .where(id: HotspotDoc.hits.select(:comment_id))
      .find_each { |comment| notice!(comment, "hotspot") }
  end

  # Idempotently creates a row for each active moderator.
  def self.notice!(notifiable, reason)
    User.active.moderators.filter_map do |mod|
      find_or_create_by!(user: mod, notifiable: notifiable, reason: reason)
    rescue ActiveRecord::RecordNotUnique
      # a concurrent request created this row between our find and create
      nil
    end
  end
end
