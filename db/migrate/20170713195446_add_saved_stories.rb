class AddSavedStories < ActiveRecord::Migration[5.1]
  def change
    create_table :saved_stories do |t|
      t.timestamps
      t.integer :user_id
      t.integer :story_id
      t.index ["user_id", "story_id"], :unique => true
    end
  end
end
