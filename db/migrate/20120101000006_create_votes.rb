class CreateVotes < ActiveRecord::Migration[4.2]
  def change
      create_table :votes do |t|
          t.integer "user_id", null: false, unsigned: true
          t.integer "story_id", null: false, unsigned: true
          t.integer "comment_id", unsigned: true
          t.integer "vote", limit: 1, null: false
          t.string "reason", limit: 1
          t.index ["user_id", "comment_id"], name: "user_id_comment_id"
          t.index ["user_id", "story_id"], name: "user_id_story_id"
      end
  end
end
