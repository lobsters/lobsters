class CreateReplyMarkers < ActiveRecord::Migration
  def change
    create_table :reply_markers do |t|
      t.integer "user_id", null: false
      t.datetime "date", null: false
      t.boolean "unread", null: false
      t.timestamps
    end

    add_index "reply_markers", ["user_id", "date"], name: "unique_reply_marker_id", using: :btree
  end
end
