class Conversation < ApplicationRecord
  before_validation :assign_short_id, :on => :create

  belongs_to :author,
             class_name: "User",
             foreign_key: "author_user_id",
             inverse_of: false
  belongs_to :recipient,
             class_name: "User",
             foreign_key: "recipient_user_id",
             inverse_of: false
  has_many :messages, dependent: :destroy

  validates :short_id, presence: true, uniqueness: true
  validates :subject, length: { maximum: 255 }, presence: true
  validate :cannot_send_to_self

  scope :involving, ->(user) do
    where(author: user, deleted_by_author_at: nil)
    .or(where("deleted_by_author_at < updated_at"))
    .or(where(recipient: user, deleted_by_recipient_at: nil))
    .or(where("deleted_by_recipient_at < updated_at"))
  end

  after_update :check_for_both_deleted

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

  def unread_by(user)
    messages.unread_by(user).any?
  end

  def latest_message
    messages.order(id: :desc).first
  end

  def to_param
    self.short_id
  end

private

  def check_for_both_deleted
    if author_deleted_after_latest_message? &&
       recipient_deleted_after_latest_message?
      destroy!
    end
  end

  def author_deleted_after_latest_message?
    deleted_by_author_at && deleted_by_author_at > latest_message.created_at
  end

  def recipient_deleted_after_latest_message?
    deleted_by_recipient_at && deleted_by_recipient_at > latest_message.created_at
  end

  def cannot_send_to_self
    if author == recipient
      errors.add(:user, "can't be you")
    end
  end
end
