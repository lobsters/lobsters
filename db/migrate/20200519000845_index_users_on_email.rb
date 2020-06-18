class IndexUsersOnEmail < ActiveRecord::Migration[5.2]
  def change
    # postgresql users: you may want https://stackoverflow.com/a/32136337
    add_index :users, :email, unique: true
  end
end
