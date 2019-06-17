class HiddenStory < ApplicationRecord
  belongs_to :user
  belongs_to :story

  scope :by, ->(user) { where(user: user) }

  def self.hide_story_for_user(story_id, user_id)
    HiddenStory.where(:user_id => user_id, :story_id =>
      story_id).first_or_initialize.save!
    ReadRibbon.hide_replies_for(story_id, user_id)
  end

  def self.unhide_story_for_user(story_id, user_id)
    HiddenStory.where(:user_id => user_id, :story_id =>
      story_id).delete_all
    ReadRibbon.unhide_replies_for(story_id, user_id)
  end
end
