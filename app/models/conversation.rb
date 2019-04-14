class Conversation < ApplicationRecord
  before_validation :assign_short_id, :on => :create

  belongs_to :author,
             class_name: "User",
             foreign_key: "author_user_id"
  belongs_to :recipient,
             class_name: "User",
             foreign_key: "recipient_user_id"
  has_many :messages

  validates :short_id, presence: true, uniqueness: true
  validates :subject, presence: true

  scope :involving, ->(user) do
    where(author: user, deleted_by_author_at: nil).
    or(where("deleted_by_author_at < updated_at")).
    or(where(recipient: user, deleted_by_recipient_at: nil)).
    or(where("deleted_by_recipient_at < updated_at"))
  end

  def partner(of:)
    if author == of
      recipient
    else
      author
    end
  end

  def assign_short_id
    self.short_id = ShortId.new(self.class).generate
  end

  def unread?
    messages.unread.any?
  end

  def last_message
    messages.last
  end
end
