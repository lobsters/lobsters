class SuggestedTitle < ActiveRecord::Base
  belongs_to :story
  belongs_to :user
end
