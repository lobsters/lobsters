class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: {type: :bigint, unsigned: true} do |t|
      # We shouldn't need an index on the user_id alone because the unique index below provides user_id in the leftmost column
      t.references :user, null: false, foreign_key: true, type: :bigint, unsigned: true, index: false
      t.references :notifiable, polymorphic: true, null: false, type: :bigint, unsigned: true
      t.datetime :read_at
      t.string :token, null: false

      t.timestamps

      t.index [:user_id, :notifiable_type, :notifiable_id], unique: true
      t.index [:token], unique: true
    end
  end
end
