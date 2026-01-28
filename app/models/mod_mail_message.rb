class ModMailMessage < ApplicationRecord
  belongs_to :mod_mail
  belongs_to :user
  has_many :notifications,
    as: :notifiable,
    dependent: :restrict_with_exception

  validates :message, presence: true, length: {within: 20..8_192}

  def linkified_message
    Markdowner.to_html(message, as_of: created_at)
  end

  def plaintext_message
    # TODO: linkify then strip tags and convert entities back
    message.to_s
  end
end
