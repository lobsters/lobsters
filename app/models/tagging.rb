class Tagging < ActiveRecord::Base
  belongs_to :tag, :inverse_of => :taggings
  belongs_to :story, :inverse_of => :taggings
end
