class AddFulltextIndicies < ActiveRecord::Migration[5.1]
  def change
    add_index(:stories, :title, :type => :fulltext)
    add_index(:stories, :description, :type => :fulltext)
    add_index(:stories, :story_cache, :type => :fulltext)

    add_index(:comments, :comment, :type => :fulltext)
  end
end
