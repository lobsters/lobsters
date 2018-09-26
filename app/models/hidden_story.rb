class HiddenStory < ApplicationRecord
  belongs_to :user
  belongs_to :story

  scope :by, ->(user) { where(user: user) }

  def self.hide_story_for_user(story_id, user_id)
    HiddenStory.where(:user_id => user_id, :story_id =>
      story_id).first_or_initialize.save!
  end
end
