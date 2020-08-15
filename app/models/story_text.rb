class StoryText < ApplicationRecord
  self.primary_key = :id

  belongs_to :story, foreign_key: :id, inverse_of: :story_text

  validates :body, presence: true, length: { :maximum => 16_777_215 }

  def self.read_through_cache(story)
    return nil unless story.url.present?

    st = StoryText.find_or_initialize_by id: story.id
    return st.body if st.body.present?

    result = StoryCacher.get_story_text(self)
    # you're here, finish
  end
end
