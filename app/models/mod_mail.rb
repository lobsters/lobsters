class ModMail < ApplicationRecord
  has_many :mod_mail_references
  has_many :comment_references, through: :mod_mail_references, source: :reference, source_type: 'Comment'
  has_many :story_references, through: :mod_mail_references, source: :reference, source_type: 'Story'
  has_many :mod_mail_recipients
  has_many :recipients, through: :mod_mail_recipients, source: :user, class_name: 'User'
  has_many :mod_mail_messages

  validates :recipients, presence: true

  def comment_reference_short_ids
    comment_references.pluck(:short_id).join(' ')
  end

  def story_reference_short_ids
    story_references.pluck(:short_id).join(' ')
  end

  def recipient_usernames
    recipients.pluck(:username).join(' ')
  end
end
