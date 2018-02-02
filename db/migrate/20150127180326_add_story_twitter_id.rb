class AddStoryTwitterId < ActiveRecord::Migration[5.1]
  def change
    add_column :stories, :twitter_id, :string, :limit => 20
    add_index :stories, [ :twitter_id ]
  end
end
