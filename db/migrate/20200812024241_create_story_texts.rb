class CreateStoryTexts < ActiveRecord::Migration[6.0]
  def up
    create_table :story_texts, id: false do |t|
      t.primary_key :id, signed: false, null: false
      t.text :body, limit: 16777215, null: false

      t.timestamp :created_at, null: false
    end
    ActiveRecord::Base.connection.execute <<~SQL
      insert low_priority ignore into story_texts (id, body)
      select id, story_cache from stories where story_cache is not null
    SQL
    remove_column :stories, :story_cache
    add_index :story_texts, :body, type: :fulltext
  end

  def down
    add_column :stories, :story_cache, :text, limit: 16777215
    ActiveRecord::Base.connection.execute <<~SQL
      update low_priority stories inner join story_texts on stories.id = story_texts.id
      set story_cache = story_texts.body
    SQL
    add_index :stories, :story_cache, type: :fulltext
    drop_table :story_texts
  end
end
