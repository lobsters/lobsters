class CreateVotes < ActiveRecord::Migration[4.2]
  def change
    create_table "votes", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.bigint "user_id", null: false, unsigned: true
      t.bigint "story_id", null: false, unsigned: true
      t.bigint "comment_id", unsigned: true
      t.integer "vote", limit: 1, null: false
      t.string "reason", limit: 1
      t.index ["story_id"], name: "votes_story_id_fk"
      t.index ["user_id", "comment_id"], name: "user_id_comment_id"
      t.index ["user_id", "story_id"], name: "user_id_story_id"
    end
  end
end
