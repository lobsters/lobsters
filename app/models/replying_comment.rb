class ReplyingComment < ApplicationRecord
  attribute :is_unread, Type::Boolean.new

  belongs_to :comment

  
  scope :for_user, ->(user_id) { where(user_id: user_id).order(comment_created_at: :desc) }
  scope :unread_replies_for, ->(user_id) { for_user(user_id).where(is_unread: true) }
  scope :comment_replies_for, ->(user_id) { for_user(user_id).where('parent_comment_id is not null') }
  scope :story_replies_for, ->(user_id) { for_user(user_id).where('parent_comment_id is null') }
  
  protected
  # This is a view, not a real table
  def readonly?
    true
  end
end
