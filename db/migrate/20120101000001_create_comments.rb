class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table :comments do |t|
      t.text "comment", limit: 3000, null: false
      t.string "short_id", limit: 10, default: "", null: false
      t.integer "story_id", null: false, unsigned: true
      t.integer "user_id", null: false, unsigned: true
      t.bigint "thread_id", unsigned: true
      t.integer "parent_comment_id", unsigned: true
      t.integer "upvotes", default: 0, null: false
      t.integer "downvotes", default: 0, null: false
      t.timestamps
    end
  end
end
