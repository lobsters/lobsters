class MoveUserSettings < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :settings, :text
  end

  def down
    remove_column :users, :settings
  end
end
