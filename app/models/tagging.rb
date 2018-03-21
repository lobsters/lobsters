class Tagging < ApplicationRecord
  belongs_to :tag, :inverse_of => :taggings
  belongs_to :story, :inverse_of => :taggings
end
