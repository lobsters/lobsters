class AddIndexBannedByUserIdForeignKeyInOrigins < ActiveRecord::Migration[7.2]
  def up
    add_index :origins, :banned_by_user_id
  end

  def down
    remove_index :origins, :banned_by_user_id
  end
end
