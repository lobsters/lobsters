# typed: false

class Tag < ApplicationRecord
  belongs_to :category
  has_many :taggings, dependent: :delete_all
  has_many :stories, through: :taggings
  has_many :tag_filters, dependent: :destroy
  has_many :filtering_users,
    class_name: "User",
    through: :tag_filters,
    source: :user,
    dependent: :delete_all

  after_save :log_modifications

  attr_accessor :edit_user_id, :stories_count
  attr_writer :filtered_count

  validates :tag, length: {maximum: 25}, presence: true,
    uniqueness: {case_sensitive: true},
    format: {with: /\A[A-Za-z0-9_\-\+]+\z/}
  validates :description, length: {maximum: 100}
  validates :hotness_mod, inclusion: {in: -10..10}
  validates :permit_by_new_users, :privileged, :active, :is_media,
    inclusion: {in: [true, false]}

  scope :active, -> { where(active: true) }
  scope :not_permitted_for_new_users, -> { where(permit_by_new_users: false) }
  scope :related, ->(tag) {
    active
      .joins(:taggings)
      .where(taggings: {story_id: Tagging.where(tag: tag).select(:story_id)})
      .where.not(id: [tag, 67]) # 67 = programming, the catch-all
      .where.not(is_media: true)
      .group(:id)
      .order(Arel.sql("COUNT(*) desc"))
      .limit(8)
  }

  def to_param
    tag
  end

  def self.all_with_filtered_counts_for(user)
    counts = TagFilter.group(:tag_id).count

    Tag.active.order(:tag).select { |t| t.can_be_applied_by?(user) }.map { |t|
      t.filtered_count = counts[t.id].to_i
      t
    }
  end

  def category_name
    category&.category
  end

  def category_name=(category)
    self.category = Category.find_by category: category
  end

  def css_class
    "tag tag_#{tag}" << (is_media? ? " tag_is_media" : "")
  end

  def user_can_filter?(user)
    active? && (!privileged? || user.try(:is_moderator?))
  end

  def can_be_applied_by?(user)
    if privileged?
      !!user.try(:is_moderator?)
    # do include tags they can't use so they submit and get error
    else
      true
    end
  end

  def filtered_count
    @filtered_count ||= TagFilter.where(tag_id: id).count
  end

  def log_modifications
    Moderation.create do |m|
      m.action = if id_previously_changed?
        "Created new tag " + attributes.map { |f, c| "with #{f} '#{c}'" }.join(", ")
      else
        "Updating tag #{tag}, " + saved_changes
          .map { |f, c| "changed #{f} from '#{c[0]}' to '#{c[1]}'" }.join(", ")
      end
      m.moderator_user_id = @edit_user_id
      m.tag_id = id
    end
  end
end
