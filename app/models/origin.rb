# typed: false

# The unique value to identify an Origin is 'identifier', not the tuple (domain, identifier).
# Origin.domain is set from the identifier to support sharing an Origin between Domains. The URLs
# foo.github.io and github.com/foo have two different Domains that both produce the Origin with
# identifier github.com/foo. That Origin's domain is set to github.com.
class Origin < ApplicationRecord
  belongs_to :domain, optional: false
  has_many :stories
  belongs_to :banned_by_user, class_name: "User", inverse_of: false, optional: true

  validates :identifier, presence: true, length: {maximum: 255}, uniqueness: true
  validates :stories_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}, presence: true
  validates :banned_reason, length: {maximum: 200}

  # weird that this isn't automatic for new records
  after_create { Origin.reset_counters(id, :stories) }

  def self./(identifier)
    find_by! identifier:
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
