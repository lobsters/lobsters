class StoryText < ApplicationRecord
  self.primary_key = :id

  belongs_to :story, foreign_key: :id, inverse_of: :story_text

  validates :body, presence: true, length: { :maximum => 16_777_215 }

  def self.fill_cache!(story)
    return nil unless story.url.present?

    return true if StoryText.where(id: story).exists?

    text = DiffBot.get_story_text(story)
    # not create! because body may be too long
    StoryText.create id: story.id, body: text
  end

  def self.cached?(story, &blk)
    if blk
      st = StoryText.find_by(id: story)
      if st.present?
        yield st.body
        return true
      end
      return false
    end

    self.where(id: story).exists?
  end
end
