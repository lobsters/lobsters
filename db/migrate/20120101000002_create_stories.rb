class CreateStories < ActiveRecord::Migration[4.2]
  def change
    create_table :stories do |t|
      t.string "url", limit: 250, default: ""
      t.string "title", limit: 150, default: "", null: false
      t.text "description", limit: 3000
      t.boolean "is_expired"
      t.boolean "is_moderated"
      t.integer "user_id", unsigned: true
      t.timestamps

      t.index ["url"], name: "url", length: 191

      t.string "short_id", limit: 6, default: "", null: false
      t.index ["short_id"], name: "unique_short_id", unique: true

      t.integer "upvotes", default: 0, null: false, unsigned: true
      t.integer "downvotes", default: 0, null: false, unsigned: true
    end
  end
end
