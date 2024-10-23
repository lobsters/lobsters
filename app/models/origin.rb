# typed: false

class Origin < ApplicationRecord
  belongs_to :domain, optional: false
  has_many :stories
  belongs_to :banned_by_user, class_name: "User", inverse_of: false, optional: true

  validates :identifier, presence: true, length: {maximum: 255}
  validates :stories_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}, presence: true
  validates :banned_reason, length: {maximum: 200}

  def identifier= s
    super(s.downcase)
  end

  def ban_by_user_for_reason!(banner, reason)
    self.banned_at = Time.current
    self.banned_by_user_id = banner.id
    self.banned_reason = reason
    save!

    m = Moderation.new
    m.moderator_user_id = banner.id
    m.origin = self
    m.action = "Banned"
    m.reason = reason
    m.save!
  end

  def unban_by_user_for_reason!(banner, reason)
    self.banned_at = nil
    self.banned_by_user_id = nil
    self.banned_reason = nil
    save!

    m = Moderation.new
    m.moderator_user_id = banner.id
    m.origin = self
    m.action = "Unbanned"
    m.reason = reason
    m.save!
  end

  def banned?
    banned_at?
  end

  def n_submitters
    stories.count("distinct user_id")
  end

  def to_param
    identifier
  end
end
