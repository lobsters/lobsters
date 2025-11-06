class ModMailMessage < ApplicationRecord
  belongs_to :mod_mail
  belongs_to :user

  validates :message, length: {within: 20..8_192}

  def linkified_message
    Markdowner.to_html(message, as_of: created_at)
  end
end
