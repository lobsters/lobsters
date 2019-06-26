class ReadRibbon < ApplicationRecord
  belongs_to :user
  belongs_to :story

  # careful with callbacks on this model; for performance the read tracking in
  # StoriesController uses .touch and RepliesController uses update_all

  def self.hide_replies_for(story_id, user_id)
    if (ribbon = find_by(user_id: user_id, story_id: story_id))
      ribbon.is_following = false
      ribbon.save!
    end
  end

  def self.unhide_replies_for(story_id, user_id)
    if (ribbon = find_by(user_id: user_id, story_id: story_id))
      ribbon.is_following = true
      ribbon.save!
    end
  end
end
