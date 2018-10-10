class CreateMessages < ActiveRecord::Migration[4.2]
  def change
    create_table "messages", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
      t.datetime "created_at"
      t.bigint "author_user_id", null: false, unsigned: true
      t.bigint "recipient_user_id", null: false, unsigned: true
      t.boolean "has_been_read", default: false
      t.string "subject", limit: 100
      t.text "body", limit: 16777215
      t.string "random_hash", limit: 30
      t.index ["recipient_user_id"], name: "messages_recipient_user_id_fk"
      t.index ["random_hash"], name: "random_hash", unique: true
    end
  end
end
