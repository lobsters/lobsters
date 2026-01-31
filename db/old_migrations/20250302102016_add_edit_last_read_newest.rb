class AddEditLastReadNewest < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :last_read_newest, :last_read_newest_story
    add_column :users, :last_read_newest_comment, :datetime, null: true, default: nil
  end
end
