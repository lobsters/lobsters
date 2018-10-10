class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table "comments", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at"
      t.string "short_id", limit: 10, default: "", null: false
      t.bigint "story_id", null: false, unsigned: true
      t.bigint "user_id", null: false, unsigned: true
      t.bigint "parent_comment_id", unsigned: true
      t.bigint "thread_id", unsigned: true
      t.text "comment", limit: 16777215, null: false
      t.integer "upvotes", default: 0, null: false
      t.integer "downvotes", default: 0, null: false
      t.index ["parent_comment_id"], name: "comments_parent_comment_id_fk"
      t.index ["short_id"], name: "short_id", unique: true
      t.index ["story_id", "short_id"], name: "story_id_short_id"
      t.index ["thread_id"], name: "thread_id"
    end
  end
end
