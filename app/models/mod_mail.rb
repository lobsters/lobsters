class ModMail < ApplicationRecord
  has_many :mod_mail_references
  has_many :comment_references, through: :mod_mail_references, source: :reference, source_type: 'Comment'
  has_many :mod_mail_recipients
  has_many :recipients, through: :mod_mail_recipients, source: :user, class_name: 'User'
  has_many :mod_mail_messages

  validates :recipients, presence: true

  def recipient_usernames
    recipients.pluck(:username).join(' ')
  end
end
