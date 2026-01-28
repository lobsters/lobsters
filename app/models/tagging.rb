# typed: false

class Tagging < ApplicationRecord
  belongs_to :tag, inverse_of: :taggings
  belongs_to :story, inverse_of: :taggings

  validates :story_id, uniqueness: {scope: :tag_id}
end
