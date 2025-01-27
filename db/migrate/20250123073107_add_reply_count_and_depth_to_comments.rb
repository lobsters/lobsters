class AddReplyCountAndDepthToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :reply_count, :integer, default: 0
    add_column :comments, :depth, :integer, default: 0
  end

  def down
    remove_column :comments, :depth
    remove_column :comments, :reply_count
  end
end
