class ReadRibbon < ApplicationRecord
  belongs_to :user
  belongs_to :story

  # careful with callbacks on this model; for performance the read tracking in
  # StoriesController uses .touch and RepliesController uses update_all

  def self.hide_replies_for(story_id, user_id)
    ribbon = find_or_create_by(user_id: user_id, story_id: story_id)
    ribbon.is_following = false
    ribbon.save!
  end
end
