# typed: false

class Hat < ApplicationRecord
  belongs_to :user
  belongs_to :granted_by_user, class_name: "User", inverse_of: false

  before_validation :assign_short_id, on: :create
  after_create :log_moderation

  include Token

  validates :hat, presence: true
  validates :hat, :link, length: {maximum: 255}
  validates :modlog_use, inclusion: {in: [true, false]}
  validates :short_id, length: {maximum: 10}, presence: true

  scope :active, -> { joins(:user).where(doffed_at: nil).merge(User.active) }

  def assign_short_id
    self.short_id = ShortId.new(self.class).generate
  end

  def doff_by_user_with_reason(user, reason)
    m = Moderation.new
    m.user_id = user_id
    m.moderator_user_id = user.is_moderator? ? user : nil
    m.action = "Doffed hat \"#{hat}\""
    m.reason = reason
    m.save!

    self.doffed_at = Time.current
    save!
  end

  def to_txt
    "(#{hat}) "
  end

  def log_moderation
    m = Moderation.new
    m.created_at = created_at
    m.user_id = user_id
    m.moderator_user_id = granted_by_user_id
    m.action = "Granted hat \"#{hat}\"" + (link.present? ?
      " (#{link})" : "")
    m.save!
  end

  def sanitized_link
    if link.include? "@"
      a = Mail::Address.new(link)
      a.domain
    else
      link
    end
  end

  def to_param
    short_id
  end
end
