# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120919195401) do

  create_table "comments", :force => true do |t|
    t.datetime "created_at",                                                                          :null => false
    t.datetime "updated_at"
    t.string   "short_id",           :limit => 10,                                 :default => "",    :null => false
    t.integer  "story_id",                                                                            :null => false
    t.integer  "user_id",                                                                             :null => false
    t.integer  "parent_comment_id"
    t.integer  "thread_id"
    t.text     "comment",                                                                             :null => false
    t.integer  "upvotes",                                                          :default => 0,     :null => false
    t.integer  "downvotes",                                                        :default => 0,     :null => false
    t.decimal  "confidence",                       :precision => 20, :scale => 19, :default => 0.0,   :null => false
    t.text     "markeddown_comment"
    t.boolean  "is_deleted",                                                       :default => false
    t.boolean  "is_moderated",                                                     :default => false
  end

  add_index "comments", ["confidence"], :name => "confidence_idx"
  add_index "comments", ["short_id"], :name => "short_id", :unique => true
  add_index "comments", ["story_id", "short_id"], :name => "story_id_short_id"
  add_index "comments", ["thread_id"], :name => "thread_id"

  create_table "invitations", :force => true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "memo"
  end

  create_table "keystores", :id => false, :force => true do |t|
    t.string  "key",   :limit => 50, :default => "", :null => false
    t.integer "value", :limit => 8
  end

  add_index "keystores", ["key"], :name => "key", :unique => true

  create_table "messages", :force => true do |t|
    t.datetime "created_at"
    t.integer  "author_user_id"
    t.integer  "recipient_user_id"
    t.boolean  "has_been_read",                       :default => false
    t.string   "subject",              :limit => 100
    t.text     "body"
    t.string   "short_id",             :limit => 30
    t.boolean  "deleted_by_author",                   :default => false
    t.boolean  "deleted_by_recipient",                :default => false
  end

  add_index "messages", ["short_id"], :name => "random_hash", :unique => true

  create_table "moderations", :force => true do |t|
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "moderator_user_id"
    t.integer  "story_id"
    t.integer  "comment_id"
    t.integer  "user_id"
    t.text     "action"
    t.text     "reason"
  end

  create_table "stories", :force => true do |t|
    t.datetime "created_at"
    t.integer  "user_id"
    t.string   "url",                    :limit => 250,                                 :default => ""
    t.string   "title",                  :limit => 150,                                 :default => "",  :null => false
    t.text     "description"
    t.string   "short_id",               :limit => 6,                                   :default => "",  :null => false
    t.integer  "is_expired",             :limit => 1,                                   :default => 0,   :null => false
    t.integer  "upvotes",                                                               :default => 0,   :null => false
    t.integer  "downvotes",                                                             :default => 0,   :null => false
    t.integer  "is_moderated",           :limit => 1,                                   :default => 0,   :null => false
    t.decimal  "hotness",                               :precision => 20, :scale => 10, :default => 0.0, :null => false
    t.text     "markeddown_description"
  end

  add_index "stories", ["hotness"], :name => "hotness_idx"
  add_index "stories", ["is_expired", "is_moderated"], :name => "is_idxes"
  add_index "stories", ["url"], :name => "url"

  create_table "tag_filters", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "user_id"
    t.integer  "tag_id"
  end

  add_index "tag_filters", ["user_id", "tag_id"], :name => "user_tag_idx"

  create_table "taggings", :force => true do |t|
    t.integer "story_id", :null => false
    t.integer "tag_id",   :null => false
  end

  add_index "taggings", ["story_id", "tag_id"], :name => "story_id_tag_id", :unique => true

  create_table "tags", :force => true do |t|
    t.string  "tag",                 :limit => 25,  :default => "",    :null => false
    t.string  "description",         :limit => 100
    t.boolean "filtered_by_default",                :default => false
    t.boolean "privileged",                         :default => false
  end

  add_index "tags", ["tag"], :name => "tag", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username",             :limit => 50
    t.string   "email",                :limit => 100
    t.string   "password_digest",      :limit => 75
    t.datetime "created_at"
    t.integer  "email_notifications",  :limit => 1,   :default => 0
    t.integer  "is_admin",             :limit => 1,   :default => 0,     :null => false
    t.string   "password_reset_token", :limit => 75
    t.string   "session_token",        :limit => 75,  :default => "",    :null => false
    t.text     "about"
    t.integer  "invited_by_user_id"
    t.boolean  "email_replies",                       :default => false
    t.boolean  "pushover_replies",                    :default => false
    t.string   "pushover_user_key"
    t.string   "pushover_device"
    t.boolean  "email_messages",                      :default => true
    t.boolean  "pushover_messages",                   :default => true
    t.boolean  "is_moderator",                        :default => false
    t.boolean  "email_mentions",                      :default => false
    t.boolean  "pushover_mentions",                   :default => false
    t.string   "rss_token"
  end

  add_index "users", ["session_token"], :name => "session_hash", :unique => true
  add_index "users", ["username"], :name => "username", :unique => true

  create_table "votes", :force => true do |t|
    t.integer "user_id",                 :null => false
    t.integer "story_id",                :null => false
    t.integer "comment_id"
    t.integer "vote",       :limit => 1, :null => false
    t.string  "reason",     :limit => 1
  end

  add_index "votes", ["user_id", "comment_id"], :name => "user_id_comment_id"
  add_index "votes", ["user_id", "story_id"], :name => "user_id_story_id"

end
