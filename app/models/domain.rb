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
  validates :replacement, length: {maximum: 255}
  validates :stories_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}, presence: true

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

  def self./(domain)
    find_by! domain:
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
    return unless saved_change_to_selector? || saved_change_to_replacement?

    # only happens for rare, manual mod edits
    Prosopite.pause do
      stories.find_each do |story|
        story.update_column(:origin_id, story.domain.find_or_create_origin(story.url)&.id)
      end
    end
  end

  def find_or_create_origin(url)
    return nil if selector.blank? || replacement.blank?
    valid?
    raise ArgumentError, "Domain not valid: #{errors.full_messages.join(", ")}" if errors.any?
    raise ArgumentError, "Can't create Origin until Domain is persisted" if new_record?

    # github.com/foo -> github.com/foo
    # github.com/foo/bar -> github.com/foo
    identifier = if url.match?(selector_regexp)
      url.sub(selector_regexp, replacement)
    else
      # if the URL isn't matched, the identifier is the bare domain (handles root + partial regexps)
      domain
    end.downcase

    # because of rails associations, `origins` is scoped to current domain object
    # find_or_create_by! returns the origin record, or raises if validations fail
    origins.find_or_create_by!(identifier: identifier)
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
