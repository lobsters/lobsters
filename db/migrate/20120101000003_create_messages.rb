class CreateMessages < ActiveRecord::Migration[4.2]
  def change
    create_table :messages do |t|
      t.string "random_hash"
      t.boolean "has_been_read"
      t.integer "author_user_id", unsigned: true
      t.integer "recipient_user_id", unsigned: true
      t.boolean "has_been_read", default: false
      t.string "subject", limit: 99
      t.text "body", limit: 990
      t.timestamps
    end
  end
end
