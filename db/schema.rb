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

ActiveRecord::Schema.define(:version => 0) do

  create_table "comments", :force => true do |t|
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at"
    t.string   "short_id",          :limit => 10, :default => "", :null => false
    t.integer  "story_id",                                        :null => false
    t.integer  "user_id",                                         :null => false
    t.integer  "parent_comment_id"
    t.integer  "thread_id"
    t.text     "comment",                                         :null => false
    t.integer  "upvotes",                         :default => 0,  :null => false
    t.integer  "downvotes",                       :default => 0,  :null => false
  end

  add_index "comments", ["short_id"], :name => "short_id", :unique => true
  add_index "comments", ["story_id", "short_id"], :name => "story_id"
  add_index "comments", ["thread_id"], :name => "thread_id"

  create_table "keystores", :primary_key => "key", :force => true do |t|
    t.integer "value", :null => false
  end

  create_table "messages", :force => true do |t|
    t.datetime "created_at"
    t.integer  "author_user_id"
    t.integer  "recipient_user_id"
    t.integer  "has_been_read",     :limit => 1,   :default => 0
    t.string   "subject",           :limit => 100
    t.text     "body"
    t.string   "random_hash",       :limit => 30
  end

  add_index "messages", ["random_hash"], :name => "random_hash", :unique => true

  create_table "stories", :force => true do |t|
    t.datetime "created_at"
    t.integer  "user_id"
    t.string   "url",          :limit => 250, :default => ""
    t.string   "title",        :limit => 150, :default => "", :null => false
    t.text     "description"
    t.string   "short_id",     :limit => 6,   :default => "", :null => false
    t.integer  "is_expired",   :limit => 1,   :default => 0,  :null => false
    t.integer  "upvotes",                     :default => 0,  :null => false
    t.integer  "downvotes",                   :default => 0,  :null => false
    t.integer  "is_moderated", :limit => 1,   :default => 0,  :null => false
  end

  add_index "stories", ["url"], :name => "url"

  create_table "taggings", :force => true do |t|
    t.integer "story_id", :null => false
    t.integer "tag_id",   :null => false
  end

  add_index "taggings", ["story_id", "tag_id"], :name => "story_id", :unique => true

  create_table "tags", :force => true do |t|
    t.string "tag",         :limit => 25,  :default => "", :null => false
    t.string "description", :limit => 100
  end

  add_index "tags", ["tag"], :name => "tag", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username",             :limit => 50
    t.string   "email",                :limit => 100
    t.string   "password_digest",      :limit => 75
    t.datetime "created_at"
    t.integer  "email_notifications",  :limit => 1,   :default => 0
    t.integer  "is_admin",             :limit => 1,   :default => 0,  :null => false
    t.string   "password_reset_token", :limit => 75
    t.string   "session_token",        :limit => 75,  :default => "", :null => false
    t.text     "about"
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

  add_index "votes", ["user_id", "comment_id"], :name => "user_id_2"
  add_index "votes", ["user_id", "story_id"], :name => "user_id"

end
