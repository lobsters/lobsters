# typed: false

class StoryText < ApplicationRecord
  self.primary_key = :id

  belongs_to :story, foreign_key: :id, inverse_of: :story_text

  validates :title, presence: true, length: {maximum: 150}
  validates :description, :body, length: {maximum: 16_777_215}

  after_create :create_fts
  after_update :update_fts
  after_destroy :destroy_fts

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

  def create_fts
    ActiveRecord::Base.connection.exec_insert("INSERT INTO story_texts_fts (rowid, title, description, body) values (?, ?, ?, ?)", nil, [self.id, self.title, self.description, self.body])
  end

  def update_fts
    # contentless-delete tables in sqlite require all the columns when updating them, see for more info:
    # https://www.sqlite.org/fts5.html#contentless_delete_tables
    if saved_change_to_attribute(:title) || saved_change_to_attribute(:description) || saved_change_to_attribute(:body)
      ActiveRecord::Base.connection.exec_update("UPDATE story_texts_fts set title = ?, description = ?, body = ? where rowid = ?", nil, [self.title, self.description, self.body, self.id])
    end
  end

  def destroy_fts
    ActiveRecord::Base.connection.exec_delete("DELETE FROM story_texts_fts where rowid = ?", nil, [self.id])
  end
end
