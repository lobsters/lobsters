class StoryText < ApplicationRecord
  self.primary_key = :id

  belongs_to :story, foreign_key: :id, inverse_of: :story_text

  validates :title, presence: true, length: {maximum: 150}
  validates :description, :body, length: {maximum: 16_777_215}

  include FullTextSearch[:title, :description, :body]

  def body=(s)
    # pass nil, truncate to column limit https://mariadb.com/kb/en/mediumtext/
    super(s ? s[...(2**24 - 1)] : s)
  end

  def self.sync!(story)
    st = find_or_initialize_by(id: story.id)
    st.assign_attributes(title: story.title, description: story.description)
    st.body = DiffBot.get_story_text(story) if st.body.blank? && story.url.present?
    st.save!
  end

  def self.cached?(story)
    body = find_by(id: story)&.body
    return false if body.blank?

    yield body if block_given?
    true
  end
end
