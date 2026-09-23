# typed: false

# The unique value to identify an Origin is 'identifier', not the tuple (domain, identifier).
# Origin.domain is set from the identifier to support sharing an Origin between Domains. The URLs
# foo.github.io and github.com/foo have two different Domains that both produce the Origin with
# identifier github.com/foo. That Origin's domain is set to github.com.
class Origin < ApplicationRecord
  belongs_to :domain
  has_many :stories
  belongs_to :banned_by_user,
    class_name: "User",
    inverse_of: false,
    optional: true
  has_one :moderation, dependent: :restrict_with_exception

  validates :identifier, presence: true, length: {maximum: 255}, uniqueness: {case_sensitive: false}
  validates :stories_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}, presence: true
  validates :banned_reason, length: {maximum: 200}
  validate :banned_at_and_reason_set_together

  include Token

  # weird that this isn't automatic for new records
  after_create { Origin.reset_counters(id, :stories) }

  def self./(identifier)
    find_by! identifier:
  end

  # the identifier picks the Domain, so unifying foo.github.io into github.com/foo moves the
  # Origin to the Domain that owns it now. Domain#find_or_create_origin supplies the fallback
  # for a host no Domain has yet.
  def identifier=(s)
    super
    found = Domain.find_by(domain: Utils::URL_RE.match("https://#{s}")&.[](:domain))
    self.domain = found if found
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

  def banned_at_and_reason_set_together
    if banned_at.present? != banned_reason.present?
      errors.add(:base, "A reason is required to ban.")
    end
  end

  def merge_into!(other)
    transaction do
      if banned? && !other.banned?
        other.assign_attributes banned_at: banned_at,
          banned_by_user_id: banned_by_user_id,
          banned_reason: banned_reason
        other.save! validate: false
      end
      Moderation.where(origin_id: id).update_all(origin_id: other.id)

      destroy!
    end

    banned?
  end

  def n_submitters
    stories.count("distinct user_id")
  end

  def to_param
    identifier
  end
end
