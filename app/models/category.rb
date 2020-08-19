class Category < ApplicationRecord
  has_many :tags,
           -> { order('tag asc') },
           dependent: :restrict_with_error,
           inverse_of: :category
  has_many :stories, through: :tags

  validates :category, length: { maximum: 25 }, presence: true,
                       uniqueness: { case_sensitive: false }, format: { without: /,/ }

  def to_param
    self.category
  end
end
