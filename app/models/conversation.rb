class Conversation < ApplicationRecord
  belongs_to(
    :author,
    class_name: User.name,
    foreign_key: "author_user_id",
  )
  belongs_to(
    :recipient,
    class_name: User.name,
    foreign_key: "recipient_user_id",
  )
  has_many :messages

  scope :involving, ->(user) do
    where(recipient: user).or(Conversation.where(author: user))
  end

  def partner(of:)
    if author == of
      recipient
    else
      author
    end
  end
end
