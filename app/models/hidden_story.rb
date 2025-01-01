# typed: false

class HiddenStory < ApplicationRecord
  belongs_to :user
  belongs_to :story

  scope :by, ->(user) { where(user: user) }

  def self.hide_story_for_user(story, user)
    HiddenStory.where(story: story, user: user).first_or_initialize.save!
    story.update_score_and_recalculate!(0, 0)
    ReadRibbon.hide_replies_for(story.id, user.id)
  end

  def self.unhide_story_for_user(story, user)
    HiddenStory.where(story: story, user: user).delete_all
    story.update_score_and_recalculate!(0, 0)
    ReadRibbon.unhide_replies_for(story.id, user.id)
  end
end
