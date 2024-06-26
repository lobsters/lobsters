# typed: false

class StoryText < ApplicationRecord
  self.primary_key = :id

  belongs_to :story, foreign_key: :id, inverse_of: :story_text

  validates :title, presence: true, length: {maximum: 150}
  validates :description, :body, length: {maximum: 16_777_215}

  def body=(s)
    # pass nil, truncate to column limit https://mariadb.com/kb/en/mediumtext/
    super(s ? s[...(2**24 - 1)] : s)
  end

  def self.fill_cache!(story)
    return true if StoryText.where(id: story).exists?

    body = DiffBot.get_story_text(story)
    StoryText.create! id: story.id, title: story.title, description: story.description, body: body
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

    where(id: story).exists?
  end
end
