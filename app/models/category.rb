# typed: false

class Category < ApplicationRecord
  has_many :tags,
    -> { order("tag asc") },
    dependent: :restrict_with_exception,
    inverse_of: :category
  has_many :stories, through: :tags
  has_one :moderation, dependent: :restrict_with_exception

  after_save :log_modifications

  include Token

  attr_accessor :edit_user_id

  NAME_FORMAT = /\A[A-Za-z0-9_-]+\z/
  NAME_MAXLENGTH = 25

  validates :category, length: {maximum: NAME_MAXLENGTH}, presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: NAME_FORMAT}

  def to_param
    category
  end

  def log_modifications
    Moderation.create do |m|
      m.action = if id_previously_changed?
        "Created new category " +
          attributes.map { |f, c| "with #{f} '#{c}'" }.join(", ")
      else
        "Updating category #{category}, " + saved_changes
          .map { |f, c| "changed #{f} from '#{c[0]}' to '#{c[1]}'" }.join(", ")
      end
      m.moderator_user_id = @edit_user_id
      m.category_id = id
    end
  end
end
