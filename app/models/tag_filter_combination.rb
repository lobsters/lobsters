# typed: false

class TagFilterCombination < ApplicationRecord
  belongs_to :user
  has_many :tag_filter_combination_tags, dependent: :destroy, inverse_of: :tag_filter_combination
  has_many :tags, through: :tag_filter_combination_tags

  MAX_TAGS_PER_COMBINATION = 15
  MAX_COMBINATIONS_PER_USER = 15

  validates :user_id, presence: true
  validates :combo_hash, presence: true
  validates :tag_count, presence: true, numericality: {greater_than: 1}
  validate :tags_count_within_limits
  validate :user_combinations_limit

  before_validation :compute_combo_hash, :compute_tag_count

  # bloom filter hash: signed 64-bit from tag ids
  def self.compute_tag_hash(tags)
    h = tags.reduce(0) { |hash, tag| hash | (1 << (tag.id % 64)) }
    h >= 2**63 ? h - 2**64 : h
  end

  private

  def compute_combo_hash
    return unless tags.any?
    self.combo_hash = self.class.compute_tag_hash(tags)
  end

  def compute_tag_count
    self.tag_count = tags.size
  end

  def tags_count_within_limits
    if tags.size < 2
      errors.add(:tags, "must have at least 2 tags")
    elsif tags.size > MAX_TAGS_PER_COMBINATION
      errors.add(:tags, "must have at most #{MAX_TAGS_PER_COMBINATION} tags")                                                                                                                
    end
  end

  def user_combinations_limit
    return unless user

    # max combos per user
    existing_count = user.tag_filter_combinations.where.not(id: id).count
    if existing_count >= MAX_COMBINATIONS_PER_USER
      errors.add(:base, "cannot have more than #{MAX_COMBINATIONS_PER_USER} tag filter combinations")
    end
  end
end
