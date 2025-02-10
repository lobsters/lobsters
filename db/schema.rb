# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_02_10_214901) do
  create_table "action_mailbox_inbound_emails", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "category", limit: 25, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category"], name: "index_categories_on_category", unique: true
  end

  create_table "comment_stats", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.date "date", null: false
    t.integer "average", null: false
    t.index ["date"], name: "index_comment_stats_on_date", unique: true
  end

  create_table "comments", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil
    t.string "short_id", limit: 10, default: "", null: false
    t.bigint "story_id", null: false, unsigned: true
    t.binary "confidence_order", limit: 3, null: false
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "parent_comment_id", unsigned: true
    t.bigint "thread_id", unsigned: true
    t.text "comment", size: :medium, null: false
    t.integer "score", default: 1, null: false
    t.integer "flags", default: 0, null: false, unsigned: true
    t.decimal "confidence", precision: 20, scale: 19, default: "0.0", null: false
    t.text "markeddown_comment", size: :medium
    t.boolean "is_deleted", default: false, null: false
    t.boolean "is_moderated", default: false, null: false
    t.boolean "is_from_email", default: false, null: false
    t.bigint "hat_id", unsigned: true
    t.integer "depth", default: 0, null: false
    t.integer "reply_count", default: 0, null: false
    t.datetime "last_reply_at"
    t.datetime "last_edited_at", null: false
    t.index ["comment"], name: "index_comments_on_comment", type: :fulltext
    t.index ["confidence"], name: "confidence_idx"
    t.index ["hat_id"], name: "comments_hat_id_fk"
    t.index ["parent_comment_id"], name: "comments_parent_comment_id_fk"
    t.index ["score"], name: "index_comments_on_score"
    t.index ["short_id"], name: "short_id", unique: true
    t.index ["story_id", "short_id"], name: "story_id_short_id"
    t.index ["thread_id"], name: "thread_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "domains", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "domain", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "banned_at", precision: nil
    t.bigint "banned_by_user_id", unsigned: true
    t.string "banned_reason", limit: 200
    t.string "selector"
    t.string "replacement"
    t.integer "stories_count", default: 0, null: false
    t.index ["banned_by_user_id"], name: "index_domains_on_banned_by_user_id"
    t.index ["domain"], name: "index_domains_on_domain", unique: true
  end

  create_table "hat_requests", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "user_id", null: false, unsigned: true
    t.string "hat", null: false
    t.string "link", null: false
    t.text "comment", null: false
    t.index ["user_id"], name: "hat_requests_user_id_fk"
  end

  create_table "hats", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "granted_by_user_id", null: false, unsigned: true
    t.string "hat", null: false
    t.string "link"
    t.boolean "modlog_use", default: false, null: false
    t.datetime "doffed_at", precision: nil
    t.string "short_id", limit: 10, null: false
    t.index ["granted_by_user_id"], name: "hats_granted_by_user_id_fk"
    t.index ["user_id"], name: "hats_user_id_fk"
  end

  create_table "hidden_stories", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.datetime "created_at"
    t.index ["story_id"], name: "hidden_stories_story_id_fk"
    t.index ["user_id", "story_id"], name: "index_hidden_stories_on_user_id_and_story_id", unique: true
  end

  create_table "invitation_requests", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "code"
    t.boolean "is_verified", default: false, null: false
    t.string "email", null: false
    t.string "name", null: false
    t.text "memo", size: :tiny
    t.string "ip_address"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "invitations", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false, unsigned: true
    t.string "email"
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "memo"
    t.datetime "used_at", precision: nil
    t.bigint "new_user_id", unsigned: true
    t.index ["new_user_id"], name: "invitations_new_user_id_fk"
    t.index ["user_id"], name: "invitations_user_id_fk"
  end

  create_table "keystores", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "key", limit: 50, default: "", null: false
    t.bigint "value"
    t.index ["key"], name: "key", unique: true
  end

  create_table "links", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "url", limit: 250, null: false
    t.string "normalized_url", null: false
    t.string "title"
    t.bigint "from_story_id", unsigned: true
    t.bigint "from_comment_id", unsigned: true
    t.bigint "to_story_id", unsigned: true
    t.bigint "to_comment_id", unsigned: true
    t.index ["from_comment_id"], name: "index_links_on_from_comment_id"
    t.index ["from_story_id"], name: "index_links_on_from_story_id"
    t.index ["normalized_url"], name: "index_links_on_normalized_url"
    t.index ["to_comment_id"], name: "index_links_on_to_comment_id"
    t.index ["to_story_id"], name: "index_links_on_to_story_id"
  end

  create_table "mastodon_apps", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_mastodon_apps_on_name", unique: true
  end

  create_table "messages", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.bigint "author_user_id", unsigned: true
    t.bigint "recipient_user_id", null: false, unsigned: true
    t.boolean "has_been_read", default: false, null: false
    t.string "subject", limit: 100
    t.text "body", size: :medium
    t.string "short_id", limit: 30
    t.boolean "deleted_by_author", default: false, null: false
    t.boolean "deleted_by_recipient", default: false, null: false
    t.bigint "hat_id", unsigned: true
    t.index ["author_user_id"], name: "index_messages_on_author_user_id"
    t.index ["hat_id"], name: "index_messages_on_hat_id"
    t.index ["recipient_user_id"], name: "messages_recipient_user_id_fk"
    t.index ["short_id"], name: "random_hash", unique: true
  end

  create_table "mod_notes", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "moderator_user_id", null: false, unsigned: true
    t.bigint "user_id", null: false, unsigned: true
    t.text "note", null: false
    t.text "markeddown_note", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["id", "user_id"], name: "index_mod_notes_on_id_and_user_id"
    t.index ["moderator_user_id"], name: "mod_notes_moderator_user_id_fk"
    t.index ["user_id"], name: "mod_notes_user_id_fk"
  end

  create_table "moderations", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "moderator_user_id", unsigned: true
    t.bigint "story_id", unsigned: true
    t.bigint "comment_id", unsigned: true
    t.bigint "user_id", unsigned: true
    t.text "action", size: :medium
    t.text "reason", size: :medium
    t.boolean "is_from_suggestions", default: false, null: false
    t.bigint "tag_id", unsigned: true
    t.bigint "domain_id"
    t.bigint "category_id"
    t.bigint "origin_id"
    t.index ["category_id"], name: "index_moderations_on_category_id"
    t.index ["comment_id"], name: "moderations_comment_id_fk"
    t.index ["created_at"], name: "index_moderations_on_created_at"
    t.index ["domain_id"], name: "index_moderations_on_domain_id"
    t.index ["moderator_user_id"], name: "moderations_moderator_user_id_fk"
    t.index ["origin_id"], name: "index_moderations_on_origin_id"
    t.index ["story_id"], name: "moderations_story_id_fk"
    t.index ["tag_id"], name: "moderations_tag_id_fk"
    t.index ["user_id"], name: "index_moderations_on_user_id"
  end

  create_table "origins", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "domain_id", null: false
    t.string "identifier", null: false
    t.integer "stories_count", default: 0, null: false
    t.datetime "banned_at"
    t.bigint "banned_by_user_id", unsigned: true
    t.string "banned_reason", limit: 200
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["banned_by_user_id"], name: "index_origins_on_banned_by_user_id"
    t.index ["domain_id"], name: "index_origins_on_domain_id"
    t.index ["identifier"], name: "index_origins_on_identifier", unique: true
  end

  create_table "read_ribbons", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "is_following", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.index ["story_id"], name: "index_read_ribbons_on_story_id"
    t.index ["user_id"], name: "index_read_ribbons_on_user_id"
  end

  create_table "saved_stories", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.index ["story_id"], name: "saved_stories_story_id_fk"
    t.index ["user_id", "story_id"], name: "index_saved_stories_on_user_id_and_story_id", unique: true
  end

  create_table "stories", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.bigint "user_id", null: false, unsigned: true
    t.string "url", limit: 250, default: ""
    t.string "normalized_url"
    t.string "title", limit: 150, default: "", null: false
    t.text "description"
    t.string "short_id", limit: 6, default: "", null: false
    t.boolean "is_deleted", default: false, null: false
    t.integer "score", default: 1, null: false
    t.integer "flags", default: 0, null: false, unsigned: true
    t.boolean "is_moderated", default: false, null: false
    t.decimal "hotness", precision: 20, scale: 10, default: "0.0", null: false
    t.text "markeddown_description", size: :medium
    t.integer "comments_count", default: 0, null: false
    t.bigint "merged_story_id", unsigned: true
    t.datetime "unavailable_at", precision: nil
    t.string "twitter_id", limit: 20
    t.boolean "user_is_author", default: false, null: false
    t.boolean "user_is_following", default: false, null: false
    t.bigint "domain_id"
    t.string "mastodon_id", limit: 25
    t.bigint "origin_id"
    t.datetime "last_comment_at"
    t.integer "stories_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.datetime "last_edited_at", null: false
    t.index ["created_at"], name: "index_stories_on_created_at"
    t.index ["domain_id"], name: "index_stories_on_domain_id"
    t.index ["hotness"], name: "hotness_idx"
    t.index ["id", "is_deleted"], name: "index_stories_on_id_and_is_deleted"
    t.index ["last_comment_at"], name: "index_stories_on_last_comment_at"
    t.index ["mastodon_id"], name: "index_stories_on_mastodon_id"
    t.index ["merged_story_id"], name: "index_stories_on_merged_story_id"
    t.index ["normalized_url"], name: "index_stories_on_normalized_url"
    t.index ["origin_id"], name: "index_stories_on_origin_id"
    t.index ["score"], name: "index_stories_on_score"
    t.index ["short_id"], name: "unique_short_id", unique: true
    t.index ["url"], name: "url", length: 191
    t.index ["user_id"], name: "index_stories_on_user_id"
  end

  create_table "story_texts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "title", limit: 150, default: "", null: false
    t.text "description", size: :medium
    t.text "body", size: :medium
    t.timestamp "created_at", default: -> { "current_timestamp() ON UPDATE current_timestamp()" }, null: false
    t.index ["title", "description", "body"], name: "index_story_texts_on_title_and_description_and_body", type: :fulltext
    t.index ["title"], name: "index_story_texts_on_title", type: :fulltext
  end

  create_table "suggested_taggings", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "tag_id", null: false, unsigned: true
    t.bigint "user_id", null: false, unsigned: true
    t.index ["story_id"], name: "suggested_taggings_story_id_fk"
    t.index ["tag_id"], name: "suggested_taggings_tag_id_fk"
    t.index ["user_id"], name: "suggested_taggings_user_id_fk"
  end

  create_table "suggested_titles", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "user_id", null: false, unsigned: true
    t.string "title", limit: 150, default: "", null: false
    t.index ["story_id"], name: "suggested_titles_story_id_fk"
    t.index ["user_id"], name: "suggested_titles_user_id_fk"
  end

  create_table "tag_filters", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "tag_id", null: false, unsigned: true
    t.index ["tag_id"], name: "tag_filters_tag_id_fk"
    t.index ["user_id", "tag_id"], name: "user_tag_idx"
  end

  create_table "taggings", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "tag_id", null: false, unsigned: true
    t.index ["story_id", "tag_id"], name: "story_id_tag_id", unique: true
    t.index ["tag_id"], name: "taggings_tag_id_fk"
  end

  create_table "tags", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "tag", limit: 25, null: false
    t.string "description", limit: 100
    t.boolean "privileged", default: false, null: false
    t.boolean "is_media", default: false, null: false
    t.boolean "active", default: true, null: false
    t.float "hotness_mod", default: 0.0
    t.boolean "permit_by_new_users", default: true, null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_tags_on_category_id"
    t.index ["tag"], name: "tag", unique: true
  end

  create_table "users", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "username", limit: 50
    t.string "email", limit: 100
    t.string "password_digest", limit: 75
    t.datetime "created_at", precision: nil
    t.boolean "is_admin", default: false, null: false
    t.string "password_reset_token", limit: 75
    t.string "session_token", limit: 75, default: "", null: false
    t.text "about", size: :medium
    t.bigint "invited_by_user_id", unsigned: true
    t.boolean "is_moderator", default: false, null: false
    t.boolean "pushover_mentions", default: false, null: false
    t.string "rss_token", limit: 75
    t.string "mailing_list_token", limit: 75
    t.integer "mailing_list_mode", default: 0
    t.integer "karma", default: 0, null: false
    t.datetime "banned_at", precision: nil
    t.bigint "banned_by_user_id", unsigned: true
    t.string "banned_reason", limit: 200
    t.datetime "deleted_at", precision: nil
    t.datetime "disabled_invite_at", precision: nil
    t.bigint "disabled_invite_by_user_id", unsigned: true
    t.string "disabled_invite_reason", limit: 200
    t.text "settings", size: :medium
    t.boolean "show_email", default: false, null: false
    t.datetime "last_read_newest"
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

  create_table "votes", id: { type: :bigint, unsigned: true }, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false, unsigned: true
    t.bigint "story_id", null: false, unsigned: true
    t.bigint "comment_id", unsigned: true
    t.integer "vote", limit: 1, null: false
    t.string "reason", limit: 1, default: "", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["comment_id"], name: "index_votes_on_comment_id"
    t.index ["story_id"], name: "votes_story_id_fk"
    t.index ["user_id", "comment_id"], name: "user_id_comment_id"
    t.index ["user_id", "story_id"], name: "user_id_story_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "comments", column: "parent_comment_id", name: "comments_parent_comment_id_fk"
  add_foreign_key "comments", "hats", name: "comments_hat_id_fk"
  add_foreign_key "comments", "stories", name: "comments_story_id_fk"
  add_foreign_key "comments", "users", name: "comments_user_id_fk"
  add_foreign_key "domains", "users", column: "banned_by_user_id"
  add_foreign_key "hat_requests", "users", name: "hat_requests_user_id_fk"
  add_foreign_key "hats", "users", column: "granted_by_user_id", name: "hats_granted_by_user_id_fk"
  add_foreign_key "hats", "users", name: "hats_user_id_fk"
  add_foreign_key "hidden_stories", "stories", name: "hidden_stories_story_id_fk"
  add_foreign_key "hidden_stories", "users", name: "hidden_stories_user_id_fk"
  add_foreign_key "invitations", "users", column: "new_user_id", name: "invitations_new_user_id_fk"
  add_foreign_key "invitations", "users", name: "invitations_user_id_fk"
  add_foreign_key "links", "comments", column: "from_comment_id"
  add_foreign_key "links", "comments", column: "to_comment_id"
  add_foreign_key "links", "stories", column: "from_story_id"
  add_foreign_key "links", "stories", column: "to_story_id"
  add_foreign_key "messages", "hats", name: "messages_hat_id_fk"
  add_foreign_key "messages", "users", column: "author_user_id"
  add_foreign_key "messages", "users", column: "recipient_user_id", name: "messages_recipient_user_id_fk"
  add_foreign_key "mod_notes", "users", column: "moderator_user_id", name: "mod_notes_moderator_user_id_fk"
  add_foreign_key "mod_notes", "users", name: "mod_notes_user_id_fk"
  add_foreign_key "moderations", "categories"
  add_foreign_key "moderations", "comments", name: "moderations_comment_id_fk"
  add_foreign_key "moderations", "domains"
  add_foreign_key "moderations", "origins"
  add_foreign_key "moderations", "stories", name: "moderations_story_id_fk"
  add_foreign_key "moderations", "tags", name: "moderations_tag_id_fk"
  add_foreign_key "moderations", "users"
  add_foreign_key "moderations", "users", column: "moderator_user_id", name: "moderations_moderator_user_id_fk"
  add_foreign_key "origins", "domains"
  add_foreign_key "origins", "users", column: "banned_by_user_id"
  add_foreign_key "read_ribbons", "stories", name: "read_ribbons_story_id_fk"
  add_foreign_key "read_ribbons", "users", name: "read_ribbons_user_id_fk"
  add_foreign_key "saved_stories", "stories", name: "saved_stories_story_id_fk"
  add_foreign_key "saved_stories", "users", name: "saved_stories_user_id_fk"
  add_foreign_key "stories", "domains"
  add_foreign_key "stories", "origins"
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
  add_foreign_key "tags", "categories"
  add_foreign_key "users", "users", column: "banned_by_user_id", name: "users_banned_by_user_id_fk"
  add_foreign_key "users", "users", column: "disabled_invite_by_user_id", name: "users_disabled_invite_by_user_id_fk"
  add_foreign_key "users", "users", column: "invited_by_user_id", name: "users_invited_by_user_id_fk"
  add_foreign_key "votes", "comments", name: "votes_comment_id_fk", on_update: :cascade, on_delete: :cascade
  add_foreign_key "votes", "stories", name: "votes_story_id_fk"
  add_foreign_key "votes", "users", name: "votes_user_id_fk"

  create_view "replying_comments", sql_definition: <<-SQL
      select `read_ribbons`.`user_id` AS `user_id`,`comments`.`id` AS `comment_id`,`read_ribbons`.`story_id` AS `story_id`,`comments`.`parent_comment_id` AS `parent_comment_id`,`comments`.`created_at` AS `comment_created_at`,`parent_comments`.`user_id` AS `parent_comment_author_id`,`comments`.`user_id` AS `comment_author_id`,`stories`.`user_id` AS `story_author_id`,`read_ribbons`.`updated_at` < `comments`.`created_at` AS `is_unread`,(select `votes`.`vote` from `votes` where `votes`.`user_id` = `read_ribbons`.`user_id` and `votes`.`comment_id` = `comments`.`id`) AS `current_vote_vote`,(select `votes`.`reason` from `votes` where `votes`.`user_id` = `read_ribbons`.`user_id` and `votes`.`comment_id` = `comments`.`id`) AS `current_vote_reason` from (((`read_ribbons` join `comments` on(`comments`.`story_id` = `read_ribbons`.`story_id`)) join `stories` on(`stories`.`id` = `comments`.`story_id`)) left join `comments` `parent_comments` on(`parent_comments`.`id` = `comments`.`parent_comment_id`)) where `read_ribbons`.`is_following` = 1 and `comments`.`user_id` <> `read_ribbons`.`user_id` and `comments`.`is_deleted` = 0 and `comments`.`is_moderated` = 0 and (`parent_comments`.`user_id` = `read_ribbons`.`user_id` or `parent_comments`.`user_id` is null and `stories`.`user_id` = `read_ribbons`.`user_id`) and `stories`.`score` > `stories`.`flags` and `comments`.`score` > `comments`.`flags` and (`parent_comments`.`id` is null or `parent_comments`.`score` > `parent_comments`.`flags` and `parent_comments`.`is_moderated` = 0 and `parent_comments`.`is_deleted` = 0) and !exists(select 1 from (`votes` `f` join `comments` `c` on(`f`.`comment_id` = `c`.`id`)) where `f`.`vote` < 0 and `f`.`user_id` = `parent_comments`.`user_id` and `c`.`user_id` = `comments`.`user_id` and `f`.`story_id` = `comments`.`story_id` limit 1) and !exists(select 1 from `hidden_stories` `h` where `h`.`story_id` = `stories`.`id` and `h`.`user_id` = `parent_comments`.`user_id` limit 1)
  SQL
end
