class AddUsernamesUserIdFkConstraintAndIndex < ActiveRecord::Migration[8.0]
  def up
    unless foreign_key_exists?(:usernames, column: :user_id)
      change_column :usernames, :user_id, :bigint, unsigned: true
      add_foreign_key :usernames, :users, column: :user_id
    end

    unless index_exists?(:usernames, :user_id)
      add_index :usernames, :user_id, name: "index_usernames_user_id"
    end
  end

  def down
    if index_exists?(:usernames, :user_id, name: "index_usernames_user_id")
      remove_index :usernames, :user_id, name: "index_usernames_user_id"
    end

    if foreign_key_exists?(:usernames, column: :user_id)
      remove_foreign_key :usernames, column: :user_id
      change_column :usernames, :user_id, :bigint, unsigned: false
    end
  end
end
