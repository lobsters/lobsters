class StoryTextSearching < ActiveRecord::Migration[7.0]
  def change
    remove_index :stories, name: "index_stories_on_title"
    remove_index :stories, name: "index_stories_on_description"
    remove_index :story_texts, name: "index_story_texts_on_body"

    add_column :story_texts, :title, :string, limit: 150, default: "", null: false, after: :id
    add_column :story_texts, :description, :text, size: :medium, after: :title
    change_column :story_texts, :body, :text, size: :medium, null: true

    # fill existing StoryTexts
    ActiveRecord::Base.connection.execute <<~SQL
      update
        story_texts inner join stories on story_texts.id = stories.id
      set
      story_texts.title = stories.title,
      story_texts.description = stories.description
    SQL

    # create StoryTexts for old failures
    Story.where.not(url: nil).left_outer_joins(:story_text).where(story_text: {id: nil}).find_each do |s|
      print "#{s.id} "
      StoryText.fill_cache!(s)
      sleep 2
    end
    puts

    # create StoryTexts for stories without URLs
    Story.where(url: nil).find_each do |s|
      StoryText.fill_cache!(s)
    end
    puts

    add_index :story_texts, [:title, :description, :body], type: :fulltext
  end
end
