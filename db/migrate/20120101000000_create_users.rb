class CreateUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string "username", limit: 50
      t.string "email", limit: 100
      t.string "password_digest", limit: 75
      t.datetime "created_at"
      t.boolean "is_admin", default: false
      t.string "password_reset_token", limit: 75
      t.string "session_token", limit: 75, default: "", null: false
      t.text "about", limit: 600
      t.index ["password_reset_token"], name: "password_reset_token", unique: true
      t.index ["session_token"], name: "session_hash", unique: true
      t.index ["username"], name: "username", unique: true
    end
  end
end
