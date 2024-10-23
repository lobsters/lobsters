# typed: false

class Link < ApplicationRecord
  belongs_to :from_story, class_name: "Story", optional: true
  belongs_to :from_comment, class_name: "Comment", optional: true
  belongs_to :to_story, class_name: "Story", optional: true
  belongs_to :to_comment, class_name: "Comment", optional: true

  validates :url, length: {maximum: 250, allow_nil: false}, presence: true
  validate :valid_url
  validates :normalized_url, length: {maximum: 255, allow_nil: false}, presence: true
  validates :title, length: {maximum: 255}
  validate :validate_from_presence_xor
  validate :validate_only_one_to

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  # no database-level index because, per https://mariadb.com/kb/en/getting-started-with-indexes/
  # > In SQL any NULL is never equal to anything, not even to another NULL. Consequently, a UNIQUE
  # > constraint will not prevent one from storing duplicate rows if they contain null values:
  validates :url, uniqueness: {scope: [:from_story, :from_comment]}
  validates :to_comment, uniqueness: {scope: [:from_story, :from_comment]}, if: ->(l) { l.to_comment.present? }
  validates :to_story, uniqueness: {scope: [:from_story, :from_comment]}, if: ->(l) { l.to_story.present? }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  scope :recently_linked_from_comments, ->(url) {
    joins(:from_comment).includes(:from_comment)
      .where(from_comment: {created_at: (7.days.ago)..})
      .where(normalized_url: Utils.normalize(url))
  }

  def url=(u)
    return if u.blank?

    super(u.to_s.strip)
    self.normalized_url = Utils.normalize(url)

    if normalized_url.starts_with? Rails.application.domain
      path = normalized_url.delete_prefix(Rails.application.domain)
      r = Rails.application.routes.recognize_path(path, method: :get)

      if r[:controller] == "comments" && %w[show redirect_from_short_id show_short_id].include?(r[:action])
        self.to_comment = Comment.find_by(short_id: r[:id])
      elsif r[:controller] == "stories" && r[:action] == "show"
        # check if the url ends with a comment anchor
        if (m = url.to_s.match(/#c_([0-9A-Za-z]{6,8}\z)/))
          self.to_comment = Comment.find_by(short_id: m[1])
        else
          self.to_story = Story.find_by(short_id: r[:id])
        end
      end
    end
  rescue ActionController::RoutingError
    # ignore invalid URLs from recognize_path
  end

  # acts idempotently, ignoring multiple Links to the same url/story/comment
  # ignores validation errors; some comments have bad links ('#', 'https://foo/', 'https://http://apple.com')
  def self.recreate_from_comment! c
    Link.transaction do
      Link.where(from_comment_id: c.id).delete_all
      c.parsed_links.each(&:save)
    end
  end

  # acts idempotently, ignoring multiple Links to the same url/story/comment
  def self.recreate_from_story! s
    Link.transaction do
      Link.where(from_story_id: s.id).delete_all
      s.parsed_links.each(&:save)
    end
  end

  private

  def valid_url
    errors.add(:url, "is not valid") unless url.match?(Utils::URL_RE)
  end

  def validate_from_presence_xor
    errors.add(:base, "from_story xor from_comment must be present") unless from_story.present? ^ from_comment.present?
  end

  def validate_only_one_to
    errors.add(:base, "Both to_story and to_comment cannot be set") if to_story.present? && to_comment.present?
  end
end
