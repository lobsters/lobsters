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

ActiveRecord::Schema.define(version: 2020_06_07_192351) do

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
    t.decimal "confidence", precision: 20, scale: 19, default: "0.0", null: false
    t.text "markeddown_comment", limit: 16777215
    t.boolean "is_deleted", default: false
    t.boolean "is_moderated", default: false
    t.boolean "is_from_email", default: false
    t.bigint "hat_id", unsigned: true
    t.index ["comment"], name: "index_comments_on_comment", type: :fulltext
    t.index ["confidence"], name: "confidence_idx"
    t.index ["hat_id"], name: "comments_hat_id_fk"
    t.index ["parent_comment_id"], name: "comments_parent_comment_id_fk"
    t.index ["short_id"], name: "short_id", unique: true
    t.index ["story_id", "short_id"], name: "story_id_short_id"
    t.index ["thread_id"], name: "thread_id"
    t.index ["user_id", "story_id", "downvotes", "created_at"], name: "downvote_index"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "domains", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "domain"
    t.boolean "is_tracker", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "banned_at"
    t.integer "banned_by_user_id"
    t.string "banned_reason", limit: 200
  end

  create_table "hat_requests", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "user_id", null: false, unsigned: true
    t.string "hat", null: false
    t.string "link", null: false
    t.text "comment", null: false
    t.index ["user_id"], name: "hat_requests_user_id_fk"
  end

  create_table "hats", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "granted_by_user_id", null: false, unsigned: true
    t.string "hat", null: false
    t.string "link", collation: "utf8mb4_general_ci"
    t.boolean "modlog_use", default: false
    t.datetime "doffed_at"
    t.index ["granted_by_user_id"], name: "hats_granted_by_user_id_fk"
    t.index ["user_id"], name: "hats_user_id_fk"
  end

  create_table "hidden_stories", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.index ["story_id"], name: "hidden_stories_story_id_fk"
    t.index ["user_id", "story_id"], name: "index_hidden_stories_on_user_id_and_story_id", unique: true
  end

  create_table "invitation_requests", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "code"
    t.boolean "is_verified", default: false
    t.string "email", null: false
    t.string "name", null: false
    t.text "memo"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.bigint "user_id", null: false, unsigned: true
    t.string "email"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "memo", limit: 16777215
    t.datetime "used_at"
    t.bigint "new_user_id", unsigned: true
    t.index ["new_user_id"], name: "invitations_new_user_id_fk"
    t.index ["user_id"], name: "invitations_user_id_fk"
  end

  create_table "keystores", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", limit: 50, default: "", null: false
    t.bigint "value"
    t.index ["key"], name: "key", unique: true
  end

  create_table "messages", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "author_user_id", null: false, unsigned: true
    t.bigint "recipient_user_id", null: false, unsigned: true
    t.boolean "has_been_read", default: false
    t.string "subject", limit: 100
    t.text "body", limit: 16777215
    t.string "short_id", limit: 30
    t.boolean "deleted_by_author", default: false
    t.boolean "deleted_by_recipient", default: false
    t.bigint "hat_id", unsigned: true
    t.index ["hat_id"], name: "index_messages_on_hat_id"
    t.index ["recipient_user_id"], name: "messages_recipient_user_id_fk"
    t.index ["short_id"], name: "random_hash", unique: true
  end

  create_table "mod_notes", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.bigint "moderator_user_id", null: false, unsigned: true
    t.bigint "user_id", null: false, unsigned: true
    t.text "note", null: false
    t.text "markeddown_note", null: false
    t.datetime "created_at", null: false
    t.index ["id", "user_id"], name: "index_mod_notes_on_id_and_user_id"
    t.index ["moderator_user_id"], name: "mod_notes_moderator_user_id_fk"
    t.index ["user_id"], name: "mod_notes_user_id_fk"
  end

  create_table "moderations", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "moderator_user_id", unsigned: true
    t.bigint "story_id", unsigned: true
    t.bigint "comment_id", unsigned: true
    t.bigint "user_id", unsigned: true
    t.text "action", limit: 16777215
    t.text "reason", limit: 16777215
    t.boolean "is_from_suggestions", default: false
    t.bigint "tag_id", unsigned: true
    t.integer "domain_id"
    t.index ["comment_id"], name: "moderations_comment_id_fk"
    t.index ["created_at"], name: "index_moderations_on_created_at"
    t.index ["domain_id"], name: "index_moderations_on_domain_id"
    t.index ["moderator_user_id"], name: "moderations_moderator_user_id_fk"
    t.index ["story_id"], name: "moderations_story_id_fk"
    t.index ["tag_id"], name: "moderations_tag_id_fk"
    t.index ["user_id"], name: "index_moderations_on_user_id"
  end

  create_table "read_ribbons", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.boolean "is_following", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.index ["story_id"], name: "index_read_ribbons_on_story_id"
    t.index ["user_id"], name: "index_read_ribbons_on_user_id"
  end

  create_table "saved_stories", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.index ["story_id"], name: "saved_stories_story_id_fk"
    t.index ["user_id", "story_id"], name: "index_saved_stories_on_user_id_and_story_id", unique: true
  end

  create_table "stories", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "user_id", null: false, unsigned: true
    t.string "url", limit: 250, default: ""
    t.string "title", limit: 150, default: "", null: false
    t.text "description", limit: 16777215
    t.string "short_id", limit: 6, default: "", null: false
    t.boolean "is_expired", default: false, null: false
    t.integer "upvotes", default: 0, null: false, unsigned: true
    t.integer "downvotes", default: 0, null: false, unsigned: true
    t.boolean "is_moderated", default: false, null: false
    t.decimal "hotness", precision: 20, scale: 10, default: "0.0", null: false
    t.text "markeddown_description", limit: 16777215
    t.text "story_cache", limit: 16777215
    t.integer "comments_count", default: 0, null: false
    t.bigint "merged_story_id", unsigned: true
    t.datetime "unavailable_at"
    t.string "twitter_id", limit: 20
    t.boolean "user_is_author", default: false
    t.boolean "user_is_following", default: false, null: false
    t.bigint "domain_id"
    t.index ["created_at"], name: "index_stories_on_created_at"
    t.index ["description"], name: "index_stories_on_description", type: :fulltext
    t.index ["domain_id"], name: "index_stories_on_domain_id"
    t.index ["hotness"], name: "hotness_idx"
    t.index ["id", "is_expired", "is_moderated"], name: "index_stories_on_id_and_is_expired_and_is_moderated"
    t.index ["merged_story_id"], name: "index_stories_on_merged_story_id"
    t.index ["short_id"], name: "unique_short_id", unique: true
    t.index ["story_cache"], name: "index_stories_on_story_cache", type: :fulltext
    t.index ["title"], name: "index_stories_on_title", type: :fulltext
    t.index ["twitter_id"], name: "index_stories_on_twitter_id"
    t.index ["url"], name: "url", length: 191
    t.index ["user_id"], name: "index_stories_on_user_id"
  end

  create_table "suggested_taggings", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "tag_id", null: false, unsigned: true
    t.bigint "user_id", null: false, unsigned: true
    t.index ["story_id"], name: "suggested_taggings_story_id_fk"
    t.index ["tag_id"], name: "suggested_taggings_tag_id_fk"
    t.index ["user_id"], name: "suggested_taggings_user_id_fk"
  end

  create_table "suggested_titles", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "user_id", null: false, unsigned: true
    t.string "title", limit: 150, default: "", null: false, collation: "utf8mb4_general_ci"
    t.index ["story_id"], name: "suggested_titles_story_id_fk"
    t.index ["user_id"], name: "suggested_titles_user_id_fk"
  end

  create_table "tag_filters", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "tag_id", null: false, unsigned: true
    t.index ["tag_id"], name: "tag_filters_tag_id_fk"
    t.index ["user_id", "tag_id"], name: "user_tag_idx"
  end

  create_table "taggings", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "tag_id", null: false, unsigned: true
    t.index ["story_id", "tag_id"], name: "story_id_tag_id", unique: true
    t.index ["tag_id"], name: "taggings_tag_id_fk"
  end

  create_table "tags", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "tag", limit: 25, null: false
    t.string "description", limit: 100
    t.boolean "privileged", default: false
    t.boolean "is_media", default: false
    t.boolean "inactive", default: false
    t.float "hotness_mod", default: 0.0
    t.boolean "permit_by_new_users", default: true, null: false
    t.index ["tag"], name: "tag", unique: true
  end

  create_table "users", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "username", limit: 50, collation: "utf8mb4_general_ci"
    t.string "email", limit: 100, collation: "utf8mb4_general_ci"
    t.string "password_digest", limit: 75, collation: "utf8mb4_general_ci"
    t.datetime "created_at"
    t.boolean "is_admin", default: false
    t.string "password_reset_token", limit: 75, collation: "utf8mb4_general_ci"
    t.string "session_token", limit: 75, default: "", null: false, collation: "utf8mb4_general_ci"
    t.text "about", limit: 16777215, collation: "utf8mb4_general_ci"
    t.bigint "invited_by_user_id", unsigned: true
    t.boolean "is_moderator", default: false
    t.boolean "pushover_mentions", default: false
    t.string "rss_token", limit: 75, collation: "utf8mb4_general_ci"
    t.string "mailing_list_token", limit: 75, collation: "utf8mb4_general_ci"
    t.integer "mailing_list_mode", default: 0
    t.integer "karma", default: 0, null: false
    t.datetime "banned_at"
    t.bigint "banned_by_user_id", unsigned: true
    t.string "banned_reason", limit: 200, collation: "utf8mb4_general_ci"
    t.datetime "deleted_at"
    t.datetime "disabled_invite_at"
    t.bigint "disabled_invite_by_user_id", unsigned: true
    t.string "disabled_invite_reason", limit: 200
    t.text "settings"
    t.index ["banned_by_user_id"], name: "users_banned_by_user_id_fk"
    t.index ["disabled_invite_by_user_id"], name: "users_disabled_invite_by_user_id_fk"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invited_by_user_id"], name: "users_invited_by_user_id_fk"
    t.index ["mailing_list_mode"], name: "mailing_list_enabled"
    t.index ["mailing_list_token"], name: "mailing_list_token", unique: true
    t.index ["password_reset_token"], name: "password_reset_token", unique: true
    t.index ["rss_token"], name: "rss_token", unique: true
    t.index ["session_token"], name: "session_hash", unique: true
    t.index ["username"], name: "username", unique: true
  end

  create_table "votes", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "comment_id", unsigned: true
    t.integer "vote", limit: 1, null: false
    t.string "reason", limit: 1
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_votes_on_comment_id"
    t.index ["story_id"], name: "votes_story_id_fk"
    t.index ["user_id", "comment_id"], name: "user_id_comment_id"
    t.index ["user_id", "story_id"], name: "user_id_story_id"
  end

  add_foreign_key "comments", "comments", column: "parent_comment_id", name: "comments_parent_comment_id_fk"
  add_foreign_key "comments", "hats", name: "comments_hat_id_fk"
  add_foreign_key "comments", "stories", name: "comments_story_id_fk"
  add_foreign_key "comments", "users", name: "comments_user_id_fk"
  add_foreign_key "hat_requests", "users", name: "hat_requests_user_id_fk"
  add_foreign_key "hats", "users", column: "granted_by_user_id", name: "hats_granted_by_user_id_fk"
  add_foreign_key "hats", "users", name: "hats_user_id_fk"
  add_foreign_key "hidden_stories", "stories", name: "hidden_stories_story_id_fk"
  add_foreign_key "hidden_stories", "users", name: "hidden_stories_user_id_fk"
  add_foreign_key "invitations", "users", column: "new_user_id", name: "invitations_new_user_id_fk"
  add_foreign_key "invitations", "users", name: "invitations_user_id_fk"
  add_foreign_key "messages", "hats", name: "messages_hat_id_fk"
  add_foreign_key "messages", "users", column: "recipient_user_id", name: "messages_recipient_user_id_fk"
  add_foreign_key "mod_notes", "users", column: "moderator_user_id", name: "mod_notes_moderator_user_id_fk"
  add_foreign_key "mod_notes", "users", name: "mod_notes_user_id_fk"
  add_foreign_key "moderations", "comments", name: "moderations_comment_id_fk"
  add_foreign_key "moderations", "stories", name: "moderations_story_id_fk"
  add_foreign_key "moderations", "tags", name: "moderations_tag_id_fk"
  add_foreign_key "moderations", "users", column: "moderator_user_id", name: "moderations_moderator_user_id_fk"
  add_foreign_key "read_ribbons", "stories", name: "read_ribbons_story_id_fk"
  add_foreign_key "read_ribbons", "users", name: "read_ribbons_user_id_fk"
  add_foreign_key "saved_stories", "stories", name: "saved_stories_story_id_fk"
  add_foreign_key "saved_stories", "users", name: "saved_stories_user_id_fk"
  add_foreign_key "stories", "domains"
  add_foreign_key "stories", "stories", column: "merged_story_id", name: "stories_merged_story_id_fk"
  add_foreign_key "stories", "users", name: "stories_user_id_fk"
  add_foreign_key "suggested_taggings", "stories", name: "suggested_taggings_story_id_fk"
  add_foreign_key "suggested_taggings", "tags", name: "suggested_taggings_tag_id_fk"
  add_foreign_key "suggested_taggings", "users", name: "suggested_taggings_user_id_fk"
  add_foreign_key "suggested_titles", "stories", name: "suggested_titles_story_id_fk"
  add_foreign_key "suggested_titles", "users", name: "suggested_titles_user_id_fk"
  add_foreign_key "tag_filters", "tags", name: "tag_filters_tag_id_fk"
  add_foreign_key "tag_filters", "users", name: "tag_filters_user_id_fk"
  add_foreign_key "taggings", "stories", name: "taggings_story_id_fk"
  add_foreign_key "taggings", "tags", name: "taggings_tag_id_fk", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users", "users", column: "banned_by_user_id", name: "users_banned_by_user_id_fk"
  add_foreign_key "users", "users", column: "disabled_invite_by_user_id", name: "users_disabled_invite_by_user_id_fk"
  add_foreign_key "users", "users", column: "invited_by_user_id", name: "users_invited_by_user_id_fk"
  add_foreign_key "votes", "comments", name: "votes_comment_id_fk", on_update: :cascade, on_delete: :cascade
  add_foreign_key "votes", "stories", name: "votes_story_id_fk"
  add_foreign_key "votes", "users", name: "votes_user_id_fk"

  create_view "replying_comments", sql_definition: <<-SQL
      select `read_ribbons`.`user_id` AS `user_id`,`comments`.`id` AS `comment_id`,`read_ribbons`.`story_id` AS `story_id`,`comments`.`parent_comment_id` AS `parent_comment_id`,`comments`.`created_at` AS `comment_created_at`,`parent_comments`.`user_id` AS `parent_comment_author_id`,`comments`.`user_id` AS `comment_author_id`,`stories`.`user_id` AS `story_author_id`,`read_ribbons`.`updated_at` < `comments`.`created_at` AS `is_unread`,(select `votes`.`vote` from `votes` where `votes`.`user_id` = `read_ribbons`.`user_id` and `votes`.`comment_id` = `comments`.`id`) AS `current_vote_vote`,(select `votes`.`reason` from `votes` where `votes`.`user_id` = `read_ribbons`.`user_id` and `votes`.`comment_id` = `comments`.`id`) AS `current_vote_reason` from (((`read_ribbons` join `comments` on(`comments`.`story_id` = `read_ribbons`.`story_id`)) join `stories` on(`stories`.`id` = `comments`.`story_id`)) left join `comments` `parent_comments` on(`parent_comments`.`id` = `comments`.`parent_comment_id`)) where `read_ribbons`.`is_following` = 1 and `comments`.`user_id` <> `read_ribbons`.`user_id` and `comments`.`is_deleted` = 0 and `comments`.`is_moderated` = 0 and (`parent_comments`.`user_id` = `read_ribbons`.`user_id` or `parent_comments`.`user_id` is null and `stories`.`user_id` = `read_ribbons`.`user_id`) and `comments`.`upvotes` - `comments`.`downvotes` >= 0 and (`parent_comments`.`id` is null or `parent_comments`.`upvotes` - `parent_comments`.`downvotes` >= 0 and `parent_comments`.`is_moderated` = 0 and `parent_comments`.`is_deleted` = 0) and !exists(select 1 from (`votes` `f` join `comments` `c` on(`f`.`comment_id` = `c`.`id`)) where `f`.`vote` < 0 and `f`.`user_id` = `parent_comments`.`user_id` and `c`.`user_id` = `comments`.`user_id` and `f`.`story_id` = `comments`.`story_id` limit 1) and cast(`stories`.`upvotes` as signed) - cast(`stories`.`downvotes` as signed) >= 0
  SQL
end
