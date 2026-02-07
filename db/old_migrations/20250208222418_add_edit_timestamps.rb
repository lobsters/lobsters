# see also https://github.com/lobsters/lobsters/pull/1469
# I have to manually grep web logs to set the correct last_edited_at, so that doesn't appear here.

class AddEditTimestamps < ActiveRecord::Migration[8.0]
  def up
    # rails wants it for cache keys, so as long as I'm here...
    add_column :stories, :updated_at, :datetime, default: nil
    Story.update_all("updated_at = created_at")
    change_column :stories, :updated_at, :datetime, null: false

    add_column :stories, :last_edited_at, :datetime, default: nil
    Story.update_all("last_edited_at = created_at")
    change_column :stories, :last_edited_at, :datetime, null: false

    add_column :comments, :last_edited_at, :datetime, default: nil
    Comment.update_all("last_edited_at = updated_at")
    change_column :comments, :last_edited_at, :datetime, null: false
  end

  def down
    remove_column :stories, :last_edited_at
    remove_column :comments, :last_edited_at
  end
end
