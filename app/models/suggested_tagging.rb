class SuggestedTagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :story
  belongs_to :user
end
