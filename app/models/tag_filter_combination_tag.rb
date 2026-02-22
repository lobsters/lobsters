# typed: false

class TagFilterCombinationTag < ApplicationRecord
  belongs_to :tag_filter_combination, inverse_of: :tag_filter_combination_tags
  belongs_to :tag

  validates :tag_id, uniqueness: {scope: :tag_filter_combination_id}
end
