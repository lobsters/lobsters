class AddUserAvatarPref < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :show_avatars, :boolean, :default => false
  end
end
