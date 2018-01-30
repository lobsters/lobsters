class ReadRibbon < ApplicationRecord
  belongs_to :user
  belongs_to :story

  def self.hide_replies_for(story_id, user_id)
    ribbon = find_by(user_id: user_id, story_id: story_id)
    ribbon.is_following = false
    ribbon.save!
  end
end
