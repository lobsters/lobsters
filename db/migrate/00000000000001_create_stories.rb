class CreateStories < ActiveRecord::Migration[4.2]
  def change
    create_table "stories", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
      t.datetime "created_at"
      t.bigint "user_id", null: false, unsigned: true
      t.string "url", limit: 250, default: ""
      t.string "title", limit: 150, default: "", null: false
      t.text "description", limit: 16777215
      t.string "short_id", limit: 6, default: "", null: false
      t.boolean "is_expired", default: false, null: false
      t.integer "upvotes", default: 0, null: false, unsigned: true
      t.integer "downvotes", default: 0, null: false, unsigned: true
      t.boolean "is_moderated", default: false, null: false
      t.index ["is_expired"], name: "index_stories_on_is_expired"
      t.index ["is_moderated"], name: "index_stories_on_is_moderated"
      t.index ["short_id"], name: "unique_short_id", unique: true
      t.index ["url"], name: "url", length: 191
    end
  end
end
