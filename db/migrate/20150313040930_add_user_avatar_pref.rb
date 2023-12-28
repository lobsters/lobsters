class AddUserAvatarPref < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :show_avatars, :boolean, default: false
  end
end
