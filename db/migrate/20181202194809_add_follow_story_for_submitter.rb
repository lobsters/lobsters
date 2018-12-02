class AddFollowStoryForSubmitter < ActiveRecord::Migration[5.2]
  def up
    add_column :stories, :user_is_following, :boolean, :default => false, :null => false
  end

  def down
    remove_column :stories, :user_is_following
  end
end
