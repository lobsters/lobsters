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

ActiveRecord::Schema.define(version: 20180130235553) do

  create_table "comments", force: :cascade do |t|
    t.datetime "created_at",                                                                    null: false
    t.datetime "updated_at"
    t.string   "short_id",           limit: 10,                                 default: "",    null: false
    t.integer  "story_id",           limit: 4,                                                  null: false
    t.integer  "user_id",            limit: 4,                                                  null: false
    t.integer  "parent_comment_id",  limit: 4
    t.integer  "thread_id",          limit: 4
    t.text     "comment",            limit: 16777215,                                           null: false
    t.integer  "upvotes",            limit: 4,                                  default: 0,     null: false
    t.integer  "downvotes",          limit: 4,                                  default: 0,     null: false
    t.decimal  "confidence",                          precision: 20, scale: 19, default: 0.0,   null: false
    t.text     "markeddown_comment", limit: 16777215
    t.boolean  "is_deleted",                                                    default: false
    t.boolean  "is_moderated",                                                  default: false
    t.boolean  "is_from_email",                                                 default: false
    t.integer  "hat_id",             limit: 4
    t.boolean  "is_dragon",                                                     default: false
  end

  add_index "comments", ["confidence"], name: "confidence_idx", using: :btree
  add_index "comments", ["short_id"], name: "short_id", unique: true, using: :btree
  add_index "comments", ["story_id", "short_id"], name: "story_id_short_id", using: :btree
  add_index "comments", ["thread_id"], name: "thread_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "hat_requests", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",    limit: 4
    t.string   "hat",        limit: 255
    t.string   "link",       limit: 255
    t.text     "comment",    limit: 65535
  end

  create_table "hats", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",            limit: 4
    t.integer  "granted_by_user_id", limit: 4
    t.string   "hat",                limit: 255
    t.string   "link",               limit: 255
  end

  create_table "hidden_stories", force: :cascade do |t|
    t.integer "user_id",  limit: 4
    t.integer "story_id", limit: 4
  end

  add_index "hidden_stories", ["user_id", "story_id"], name: "index_hidden_stories_on_user_id_and_story_id", unique: true, using: :btree

  create_table "invitation_requests", force: :cascade do |t|
    t.string   "code",        limit: 255
    t.boolean  "is_verified",               default: false
    t.string   "email",       limit: 255
    t.string   "name",        limit: 255
    t.text     "memo",        limit: 65535
    t.string   "ip_address",  limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "invitations", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "email",      limit: 255
    t.string   "code",       limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "memo",       limit: 16777215
  end

  create_table "keystores", id: false, force: :cascade do |t|
    t.string  "key",   limit: 50, default: "", null: false
    t.integer "value", limit: 8
  end

  add_index "keystores", ["key"], name: "key", unique: true, using: :btree

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at"
    t.integer  "author_user_id",       limit: 4
    t.integer  "recipient_user_id",    limit: 4
    t.boolean  "has_been_read",                         default: false
    t.string   "subject",              limit: 100
    t.text     "body",                 limit: 16777215
    t.string   "short_id",             limit: 30
    t.boolean  "deleted_by_author",                     default: false
    t.boolean  "deleted_by_recipient",                  default: false
  end

  add_index "messages", ["short_id"], name: "random_hash", unique: true, using: :btree

  create_table "moderations", force: :cascade do |t|
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.integer  "moderator_user_id",   limit: 4
    t.integer  "story_id",            limit: 4
    t.integer  "comment_id",          limit: 4
    t.integer  "user_id",             limit: 4
    t.text     "action",              limit: 16777215
    t.text     "reason",              limit: 16777215
    t.boolean  "is_from_suggestions",                  default: false
  end

  create_table "read_ribbons", force: :cascade do |t|
    t.boolean  "is_following",           default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",      limit: 4
    t.integer  "story_id",     limit: 4
  end

  add_index "read_ribbons", ["story_id"], name: "index_read_ribbons_on_story_id", using: :btree
  add_index "read_ribbons", ["user_id"], name: "index_read_ribbons_on_user_id", using: :btree

  create_table "stories", force: :cascade do |t|
    t.datetime "created_at"
    t.integer  "user_id",                limit: 4
    t.string   "url",                    limit: 250,                                default: ""
    t.string   "title",                  limit: 150,                                default: "",    null: false
    t.text     "description",            limit: 16777215
    t.string   "short_id",               limit: 6,                                  default: "",    null: false
    t.boolean  "is_expired",                                                        default: false, null: false
    t.integer  "upvotes",                limit: 4,                                  default: 0,     null: false
    t.integer  "downvotes",              limit: 4,                                  default: 0,     null: false
    t.boolean  "is_moderated",                                                      default: false, null: false
    t.decimal  "hotness",                                 precision: 20, scale: 10, default: 0.0,   null: false
    t.text     "markeddown_description", limit: 16777215
    t.text     "story_cache",            limit: 16777215
    t.integer  "comments_count",         limit: 4,                                  default: 0,     null: false
    t.integer  "merged_story_id",        limit: 4
    t.datetime "unavailable_at"
    t.string   "twitter_id",             limit: 20
    t.boolean  "user_is_author",                                                    default: false
  end

  add_index "stories", ["created_at"], name: "index_stories_on_created_at", using: :btree
  add_index "stories", ["hotness"], name: "hotness_idx", using: :btree
  add_index "stories", ["is_expired", "is_moderated"], name: "is_idxes", using: :btree
  add_index "stories", ["merged_story_id"], name: "index_stories_on_merged_story_id", using: :btree
  add_index "stories", ["short_id"], name: "unique_short_id", unique: true, using: :btree
  add_index "stories", ["twitter_id"], name: "index_stories_on_twitter_id", using: :btree
  add_index "stories", ["url"], name: "url", length: {"url"=>191}, using: :btree

  create_table "suggested_taggings", force: :cascade do |t|
    t.integer "story_id", limit: 4
    t.integer "tag_id",   limit: 4
    t.integer "user_id",  limit: 4
  end

  create_table "suggested_titles", force: :cascade do |t|
    t.integer "story_id", limit: 4
    t.integer "user_id",  limit: 4
    t.string  "title",    limit: 150, null: false
  end

  create_table "tag_filters", force: :cascade do |t|
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "user_id",    limit: 4
    t.integer  "tag_id",     limit: 4
  end

  add_index "tag_filters", ["user_id", "tag_id"], name: "user_tag_idx", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer "story_id", limit: 4, null: false
    t.integer "tag_id",   limit: 4, null: false
  end

  add_index "taggings", ["story_id", "tag_id"], name: "story_id_tag_id", unique: true, using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "tag",         limit: 25,  default: "",    null: false
    t.string  "description", limit: 100
    t.boolean "privileged",              default: false
    t.boolean "is_media",                default: false
    t.boolean "inactive",                default: false
    t.float   "hotness_mod", limit: 24,  default: 0.0
  end

  add_index "tags", ["tag"], name: "tag", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username",                   limit: 50
    t.string   "email",                      limit: 100
    t.string   "password_digest",            limit: 75
    t.datetime "created_at"
    t.boolean  "is_admin",                                    default: false
    t.string   "password_reset_token",       limit: 75
    t.string   "session_token",              limit: 75,       default: "",    null: false
    t.text     "about",                      limit: 16777215
    t.integer  "invited_by_user_id",         limit: 4
    t.boolean  "is_moderator",                                default: false
    t.boolean  "pushover_mentions",                           default: false
    t.string   "rss_token",                  limit: 75
    t.string   "mailing_list_token",         limit: 75
    t.integer  "mailing_list_mode",          limit: 4,        default: 0
    t.integer  "karma",                      limit: 4,        default: 0,     null: false
    t.datetime "banned_at"
    t.integer  "banned_by_user_id",          limit: 4
    t.string   "banned_reason",              limit: 200
    t.datetime "deleted_at"
    t.datetime "disabled_invite_at"
    t.integer  "disabled_invite_by_user_id", limit: 4
    t.string   "disabled_invite_reason",     limit: 200
    t.text     "settings",                   limit: 65535
  end

  add_index "users", ["mailing_list_mode"], name: "mailing_list_enabled", using: :btree
  add_index "users", ["mailing_list_token"], name: "mailing_list_token", unique: true, using: :btree
  add_index "users", ["password_reset_token"], name: "password_reset_token", unique: true, using: :btree
  add_index "users", ["rss_token"], name: "rss_token", unique: true, using: :btree
  add_index "users", ["session_token"], name: "session_hash", unique: true, using: :btree
  add_index "users", ["username"], name: "username", unique: true, using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer "user_id",    limit: 4, null: false
    t.integer "story_id",   limit: 4, null: false
    t.integer "comment_id", limit: 4
    t.integer "vote",       limit: 1, null: false
    t.string  "reason",     limit: 1
  end

  add_index "votes", ["comment_id"], name: "index_votes_on_comment_id", using: :btree
  add_index "votes", ["user_id", "comment_id"], name: "user_id_comment_id", using: :btree
  add_index "votes", ["user_id", "story_id"], name: "user_id_story_id", using: :btree


  create_view "replying_comments",  sql_definition: <<-SQL
      select `test`.`read_ribbons`.`user_id` AS `user_id`,`test`.`comments`.`id` AS `comment_id`,`test`.`read_ribbons`.`story_id` AS `story_id`,`test`.`comments`.`parent_comment_id` AS `parent_comment_id`,`test`.`comments`.`created_at` AS `comment_created_at`,`parent_comments`.`user_id` AS `parent_comment_author_id`,`test`.`comments`.`user_id` AS `comment_author_id`,`test`.`stories`.`user_id` AS `story_author_id`,`test`.`read_ribbons`.`updated_at` < `test`.`comments`.`created_at` AS `is_unread`,(select `test`.`votes`.`vote` from `test`.`votes` where `test`.`votes`.`user_id` = `test`.`read_ribbons`.`user_id` and `test`.`votes`.`comment_id` = `test`.`comments`.`id`) AS `current_vote_vote`,(select `test`.`votes`.`reason` from `test`.`votes` where `test`.`votes`.`user_id` = `test`.`read_ribbons`.`user_id` and `test`.`votes`.`comment_id` = `test`.`comments`.`id`) AS `current_vote_reason` from (((`test`.`read_ribbons` join `test`.`comments` on(`test`.`comments`.`story_id` = `test`.`read_ribbons`.`story_id`)) join `test`.`stories` on(`test`.`stories`.`id` = `test`.`comments`.`story_id`)) left join `test`.`comments` `parent_comments` on(`parent_comments`.`id` = `test`.`comments`.`parent_comment_id`)) where `test`.`read_ribbons`.`is_following` = 1 and `test`.`comments`.`user_id` <> `test`.`read_ribbons`.`user_id` and `test`.`comments`.`is_deleted` = 0 and `test`.`comments`.`is_moderated` = 0 and (`parent_comments`.`user_id` = `test`.`read_ribbons`.`user_id` or `parent_comments`.`user_id` is null and `test`.`stories`.`user_id` = `test`.`read_ribbons`.`user_id`) and `test`.`comments`.`upvotes` - `test`.`comments`.`downvotes` >= 0 and (`parent_comments`.`id` is null or `parent_comments`.`upvotes` - `parent_comments`.`downvotes` >= 0) and cast(`test`.`stories`.`upvotes` as signed) - cast(`test`.`stories`.`downvotes` as signed) >= 0
  SQL

end
