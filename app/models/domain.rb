# typed: false

class Domain < ApplicationRecord
  has_many :stories
  belongs_to :banned_by_user,
    class_name: "User",
    inverse_of: false,
    optional: true
  has_many :origins

  validates :banned_reason, length: {maximum: 200}
  validates :domain, presence: true, length: {maximum: 255}, uniqueness: {case_sensitive: false}
  validates :selector, length: {maximum: 255}

  validate :valid_selector

  after_save :update_origins

  def valid_selector
    return if selector.nil?

    if selector.include? "\n"
      errors.add(:selector, "no newlines")
      return
    end

    selector_regexp
  rescue RegexpError => e
    errors.add(:selector, "is an invalid Regexp: #{e.message}")
  end

  def selector=(s)
    s = s.strip
    s = "\\A#{s}" unless s.starts_with?("\\A")
    s = "#{s}\\z" unless s.ends_with?("\\z")
    super
  end

  def selector_regexp
    Regexp.new(selector, Regexp::IGNORECASE, timeout: 0.1)
  end

  def update_origins
    return unless selector_previously_changed? || replacement_previously_changed?

    stories.find_each do |story|
      story.origin = origin(story.url)
    end
  end

  def origin(url)
    return domain if selector.blank? || replacement.blank?
    valid?
    raise ArgumentError if errors.any?

    # github.com/foo -> github.com/foo
    # github.com/foo/bar -> github.com/foo
    if url.match?(selector_regexp)
      identifier = url.sub(selector_regexp, replacement)
      Origin.find_or_create_by(identifier: identifier)
    else
      # if the URL isn't matched, the identifier is the bare domain (handles root + partial regexps)
      Origin.find_or_create_by(identifier: domain)
    end
  end

  def ban_by_user_for_reason!(banner, reason)
    self.banned_at = Time.current
    self.banned_by_user_id = banner.id
    self.banned_reason = reason
    save!

    m = Moderation.new
    m.moderator_user_id = banner.id
    m.domain = self
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
    m.domain = self
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
    domain
  end
end
