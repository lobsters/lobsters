class IndexStoryTitles < ActiveRecord::Migration[7.0]
  def change
    add_index :story_texts, [:title], type: :fulltext
  end
end
