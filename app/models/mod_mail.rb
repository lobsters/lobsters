class ModMail < ApplicationRecord
  has_many :mod_mail_references, dependent: :restrict_with_error
  has_many :comment_references, through: :mod_mail_references, source: :reference, source_type: "Comment"
  has_many :story_references, through: :mod_mail_references, source: :reference, source_type: "Story"
  has_many :mod_mail_recipients, dependent: :restrict_with_error
  has_many :recipients, through: :mod_mail_recipients, source: :user, class_name: "User", dependent: :restrict_with_error
  has_many :mod_mail_messages, dependent: :restrict_with_error

  has_one :mod_activity, inverse_of: :item

  validates :short_id, length: {maximum: 10}, presence: true, uniqueness: true
  validates :recipients, :subject, presence: true
  validates :subject, length: {maximum: 255}

  before_validation :assign_short_id, on: :create
  after_create_commit -> { ModActivity.create_for! self }

  def assign_short_id
    self.short_id = ShortId.new(self.class).generate
  end

  def comment_reference_short_ids
    comment_references.pluck(:short_id).join(" ")
  end

  def story_reference_short_ids
    story_references.pluck(:short_id).join(" ")
  end

  def recipient_usernames
    recipients.pluck(:username).join(" ")
  end

  def to_param
    short_id
  end
end
