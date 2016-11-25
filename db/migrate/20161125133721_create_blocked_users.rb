class CreateBlockedUsers < ActiveRecord::Migration
  def change
    create_table :blocked_users do |t|
      t.references :user, index: true
      t.integer :blocked_user_id

      t.timestamps
    end
  end
end
