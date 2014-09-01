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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140901013149) do

  create_table "comments", force: true do |t|
    t.datetime "created_at",                                                                    null: false
    t.datetime "updated_at"
    t.string   "short_id",           limit: 10,                                 default: "",    null: false
    t.integer  "story_id",                                                                      null: false
    t.integer  "user_id",                                                                       null: false
    t.integer  "parent_comment_id"
    t.integer  "thread_id"
    t.text     "comment",            limit: 16777215,                                           null: false
    t.integer  "upvotes",                                                       default: 0,     null: false
    t.integer  "downvotes",                                                     default: 0,     null: false
    t.decimal  "confidence",                          precision: 20, scale: 19, default: 0.0,   null: false
    t.text     "markeddown_comment", limit: 16777215
    t.boolean  "is_deleted",                                                    default: false
    t.boolean  "is_moderated",                                                  default: false
    t.boolean  "is_from_email",                                                 default: false
  end

  add_index "comments", ["confidence"], name: "confidence_idx", using: :btree
  add_index "comments", ["short_id"], name: "short_id", unique: true, using: :btree
  add_index "comments", ["story_id", "short_id"], name: "story_id_short_id", using: :btree
  add_index "comments", ["thread_id"], name: "thread_id", using: :btree

  create_table "invitation_requests", force: true do |t|
    t.string   "code"
    t.boolean  "is_verified", default: false
    t.string   "email"
    t.string   "name"
    t.text     "memo"
    t.string   "ip_address"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "invitations", force: true do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "code"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "memo",       limit: 16777215
  end

  create_table "keystores", id: false, force: true do |t|
    t.string  "key",   limit: 50, default: "", null: false
    t.integer "value", limit: 8
  end

  add_index "keystores", ["key"], name: "key", unique: true, using: :btree

  create_table "messages", force: true do |t|
    t.datetime "created_at"
    t.integer  "author_user_id"
    t.integer  "recipient_user_id"
    t.boolean  "has_been_read",                         default: false
    t.string   "subject",              limit: 100
    t.text     "body",                 limit: 16777215
    t.string   "short_id",             limit: 30
    t.boolean  "deleted_by_author",                     default: false
    t.boolean  "deleted_by_recipient",                  default: false
  end

  add_index "messages", ["short_id"], name: "random_hash", unique: true, using: :btree

  create_table "moderations", force: true do |t|
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "moderator_user_id"
    t.integer  "story_id"
    t.integer  "comment_id"
    t.integer  "user_id"
    t.text     "action",            limit: 16777215
    t.text     "reason",            limit: 16777215
  end

  create_table "stories", force: true do |t|
    t.datetime "created_at"
    t.integer  "user_id"
    t.string   "url",                    limit: 250,                                default: ""
    t.string   "title",                  limit: 150,                                default: "",  null: false
    t.text     "description",            limit: 16777215
    t.string   "short_id",               limit: 6,                                  default: "",  null: false
    t.integer  "is_expired",             limit: 1,                                  default: 0,   null: false
    t.integer  "upvotes",                                                           default: 0,   null: false
    t.integer  "downvotes",                                                         default: 0,   null: false
    t.integer  "is_moderated",           limit: 1,                                  default: 0,   null: false
    t.decimal  "hotness",                                 precision: 20, scale: 10, default: 0.0, null: false
    t.text     "markeddown_description", limit: 16777215
    t.text     "story_cache",            limit: 16777215
    t.integer  "comments_count",                                                    default: 0,   null: false
    t.integer  "merged_story_id"
  end

  add_index "stories", ["hotness"], name: "hotness_idx", using: :btree
  add_index "stories", ["is_expired", "is_moderated"], name: "is_idxes", using: :btree
  add_index "stories", ["merged_story_id"], name: "index_stories_on_merged_story_id", using: :btree
  add_index "stories", ["short_id"], name: "unique_short_id", unique: true, using: :btree
  add_index "stories", ["url"], name: "url", length: {"url"=>191}, using: :btree

  create_table "tag_filters", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
    t.integer  "tag_id"
  end

  add_index "tag_filters", ["user_id", "tag_id"], name: "user_tag_idx", using: :btree

  create_table "taggings", force: true do |t|
    t.integer "story_id", null: false
    t.integer "tag_id",   null: false
  end

  add_index "taggings", ["story_id", "tag_id"], name: "story_id_tag_id", unique: true, using: :btree

  create_table "tags", force: true do |t|
    t.string  "tag",         limit: 25,  default: "",    null: false
    t.string  "description", limit: 100
    t.boolean "privileged",              default: false
    t.boolean "is_media",                default: false
    t.boolean "inactive",                default: false
    t.integer "hotness_mod",             default: 0
  end

  add_index "tags", ["tag"], name: "tag", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "username",             limit: 50
    t.string   "email",                limit: 100
    t.string   "password_digest",      limit: 75
    t.datetime "created_at"
    t.boolean  "email_notifications",                   default: false
    t.boolean  "is_admin",                              default: false
    t.string   "password_reset_token", limit: 75
    t.string   "session_token",        limit: 75,       default: "",    null: false
    t.text     "about",                limit: 16777215
    t.integer  "invited_by_user_id"
    t.boolean  "email_replies",                         default: false
    t.boolean  "pushover_replies",                      default: false
    t.string   "pushover_user_key"
    t.string   "pushover_device"
    t.boolean  "email_messages",                        default: true
    t.boolean  "pushover_messages",                     default: true
    t.boolean  "is_moderator",                          default: false
    t.boolean  "email_mentions",                        default: false
    t.boolean  "pushover_mentions",                     default: false
    t.string   "rss_token",            limit: 75
    t.string   "mailing_list_token",   limit: 75
    t.integer  "mailing_list_mode",                     default: 0
    t.integer  "karma",                                 default: 0,     null: false
    t.datetime "banned_at"
    t.integer  "banned_by_user_id"
    t.string   "banned_reason",        limit: 200
    t.datetime "deleted_at"
    t.string   "pushover_sound"
  end

  add_index "users", ["mailing_list_mode"], name: "mailing_list_enabled", using: :btree
  add_index "users", ["mailing_list_token"], name: "mailing_list_token", unique: true, using: :btree
  add_index "users", ["password_reset_token"], name: "password_reset_token", unique: true, using: :btree
  add_index "users", ["rss_token"], name: "rss_token", unique: true, using: :btree
  add_index "users", ["session_token"], name: "session_hash", unique: true, using: :btree
  add_index "users", ["username"], name: "username", unique: true, using: :btree

  create_table "votes", force: true do |t|
    t.integer "user_id",              null: false
    t.integer "story_id",             null: false
    t.integer "comment_id"
    t.integer "vote",       limit: 1, null: false
    t.string  "reason",     limit: 1
  end

  add_index "votes", ["user_id", "comment_id"], name: "user_id_comment_id", using: :btree
  add_index "votes", ["user_id", "story_id"], name: "user_id_story_id", using: :btree

end
