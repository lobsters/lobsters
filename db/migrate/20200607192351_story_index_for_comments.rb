class StoryIndexForComments < ActiveRecord::Migration[5.2]
  def change
    remove_index :stories, name: "index_stories_on_is_expired"
    remove_index :stories, name:  "index_stories_on_is_moderated"
    remove_index :stories, name:  "is_idxes"
    add_index :stories, [:id, :is_expired]
  end
end
