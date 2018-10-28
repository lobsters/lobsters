class AddFulltextIndicies < ActiveRecord::Migration[4.2]
  def change
    add_index :stories, :title, using: :gin
    add_index :stories, :description, using: :gin
    add_index :stories, :story_cache, using: :gin

    add_index :comments, :comment, using: :gin
  end
end
