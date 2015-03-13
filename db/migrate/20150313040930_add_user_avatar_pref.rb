class AddUserAvatarPref < ActiveRecord::Migration
  def change
    add_column :users, :show_avatars, :boolean, :default => false
  end
end
