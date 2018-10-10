class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table "users", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "username", limit: 50, collation: "utf8mb4_general_ci"
      t.string "email", limit: 100, collation: "utf8mb4_general_ci"
      t.string "password_digest", limit: 75, collation: "utf8mb4_general_ci"
      t.datetime "created_at"
      t.boolean "is_admin", default: false
      t.string "password_reset_token", limit: 75, collation: "utf8mb4_general_ci"
      t.string "session_token", limit: 75, default: "", null: false, collation: "utf8mb4_general_ci"
      t.text "about", limit: 16777215, collation: "utf8mb4_general_ci"
      t.boolean "email_notifications", default: true
      t.index ["password_reset_token"], name: "password_reset_token", unique: true
      t.index ["session_token"], name: "session_hash", unique: true
      t.index ["username"], name: "username", unique: true
    end
  end
end
