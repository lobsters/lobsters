class ReplyingComment < ApplicationRecord
  attribute :is_unread, :boolean

  belongs_to :comment

  protected
  # This is a view, not a real table
  def readonly?
    true
  end
end
