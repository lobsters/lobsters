# typed: false

class ReplyingComment < ApplicationRecord
  attribute :is_unread, :boolean

  belongs_to :comment

  scope :for_user, ->(user_id) {
    where(user_id: user_id)
      .order(comment_created_at: :desc)
      .preload(comment: [:hat, {story: :user}, :user])
  }
  scope :unread_replies_for, ->(user_id) { for_user(user_id).where(is_unread: true) }
  scope :comment_replies_for,
    ->(user_id) { for_user(user_id).where.not(parent_comment_id: nil) }
  scope :story_replies_for, ->(user_id) { for_user(user_id).where(parent_comment_id: nil) }

  protected

  # This is a view, not a real table
  def readonly?
    true
  end
end
