class AddBasicTables < ActiveRecord::Migration[4.2]
  def change
    create_table "comments" do |t|
      t.datetime "created_at",                                      :null => false
      t.datetime "updated_at"
      t.string   "short_id",          :limit => 10, :default => "", :null => false
      t.integer  "story_id",                                        :null => false
      t.integer  "user_id",                                         :null => false
      t.integer  "parent_comment_id"
      t.integer  "thread_id"
      t.text     "comment",                                         :null => false
      t.integer  "upvotes",                         :default => 0,  :null => false, unsined: true
      t.integer  "downvotes",                       :default => 0,  :null => false, unsined: true
    end

    add_index "comments", ["short_id"], :name => "short_id", :unique => true
    add_index "comments", ["story_id", "short_id"], :name => "story_id_short_id"
    add_index "comments", ["thread_id"], :name => "thread_id"

    create_table "keystores", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
      t.string "key", limit: 50, default: "", null: false
      t.bigint "value"
      t.index ["key"], name: "key", unique: true
    end

    create_table "messages" do |t|
      t.datetime "created_at"
      t.integer  "author_user_id"
      t.integer  "recipient_user_id"
      t.integer  "has_been_read",     :limit => 1,   :default => 0
      t.string   "subject",           :limit => 100
      t.text     "body"
      t.string   "random_hash",       :limit => 30
    end

    add_index "messages", ["random_hash"], :name => "random_hash", :unique => true

    create_table "stories" do |t|
      t.datetime "created_at"
      t.integer  "user_id"
      t.string   "url",          :limit => 250, :default => ""
      t.string   "title",        :limit => 150, :default => "", :null => false
      t.text     "description"
      t.string   "short_id",     :limit => 6,   :default => "", :null => false
      t.integer  "is_expired",   :limit => 1,   :default => 0,  :null => false
      t.unsigned_integer  "upvotes",                     :default => 0,  :null => false
      t.unsigned_integer  "downvotes",                   :default => 0,  :null => false
      t.integer  "is_moderated", :limit => 1,   :default => 0,  :null => false
    end

    add_index "stories", ["url"], :name => "url", length: 191

    create_table "taggings" do |t|
      t.integer "story_id", :null => false
      t.integer "tag_id",   :null => false
    end

    add_index "taggings", ["story_id", "tag_id"], :name => "story_id_tag_id", :unique => true

    create_table "tags" do |t|
      t.string "tag",         :limit => 25,  :default => "", :null => false
      t.string "description", :limit => 100
    end

    add_index "tags", ["tag"], :name => "tag", :unique => true

    create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.string   "username",             :limit => 50, collation: "utf8mb4_general_ci"
      t.string   "email",                :limit => 100, collation: "utf8mb4_general_ci"
      t.string   "password_digest",      :limit => 75, collation: "utf8mb4_general_ci"
      t.datetime "created_at"
      t.integer  "email_notifications",  :limit => 1,   :default => 0
      t.integer  "is_admin",             :limit => 1,   :default => 0,  :null => false
      t.string   "password_reset_token", :limit => 75, collation: "utf8mb4_general_ci"
      t.string   "session_token",        :limit => 75,  :default => "", :null => false, collation: "utf8mb4_general_ci"
      t.text     "about", limit: 16777215, collation: "utf8mb4_general_ci"
    end

    add_index "users", ["session_token"], :name => "session_hash", :unique => true
    add_index "users", ["username"], :name => "username", :unique => true

    create_table "votes" do |t|
      t.integer "user_id",                 :null => false
      t.integer "story_id",                :null => false
      t.integer "comment_id"
      t.integer "vote",       :limit => 1, :null => false
      t.string  "reason",     :limit => 1
    end

    add_index "votes", ["user_id", "comment_id"], :name => "user_id_comment_id"
    add_index "votes", ["user_id", "story_id"], :name => "user_id_story_id"
  end
end
