class AddKeys < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key "comments", "hats", name: "comments_hat_id_fk"
    add_foreign_key "comments", "comments", column: "parent_comment_id", name: "comments_parent_comment_id_fk"
    add_foreign_key "comments", "stories", name: "comments_story_id_fk"
    add_foreign_key "comments", "users", name: "comments_user_id_fk"
    # add_foreign_key "hat_requests", "users", name: "hat_requests_user_id_fk"
    # add_foreign_key "hats", "users", column: "granted_by_user_id", name: "hats_granted_by_user_id_fk"
    # add_foreign_key "hats", "users", name: "hats_user_id_fk"
    # add_foreign_key "hidden_stories", "stories", name: "hidden_stories_story_id_fk"
    # add_foreign_key "hidden_stories", "users", name: "hidden_stories_user_id_fk"
    # add_foreign_key "invitations", "users", column: "new_user_id", name: "invitations_new_user_id_fk"
    # add_foreign_key "invitations", "users", name: "invitations_user_id_fk"
    add_foreign_key "messages", "users", column: "author_user_id", name: "messages_author_user_id_fk"
    # add_foreign_key "messages", "hats", name: "messages_hat_id_fk"
    add_foreign_key "messages", "users", column: "recipient_user_id", name: "messages_recipient_user_id_fk"
    # add_foreign_key "mod_notes", "users", column: "moderator_user_id", name: "mod_notes_moderator_user_id_fk"
    # add_foreign_key "mod_notes", "users", name: "mod_notes_user_id_fk"
    # add_foreign_key "moderations", "comments", name: "moderations_comment_id_fk"
    # add_foreign_key "moderations", "users", column: "moderator_user_id", name: "moderations_moderator_user_id_fk"
    # add_foreign_key "moderations", "stories", name: "moderations_story_id_fk"
    # add_foreign_key "moderations", "tags", name: "moderations_tag_id_fk"
    # add_foreign_key "moderations", "users", name: "moderations_user_id_fk"
    # add_foreign_key "read_ribbons", "stories", name: "read_ribbons_story_id_fk"
    # add_foreign_key "read_ribbons", "users", name: "read_ribbons_user_id_fk"
    # add_foreign_key "saved_stories", "stories", name: "saved_stories_story_id_fk"
    # add_foreign_key "saved_stories", "users", name: "saved_stories_user_id_fk"
    # add_foreign_key "stories", "stories", column: "merged_story_id", name: "stories_merged_story_id_fk"
    add_foreign_key "stories", "users", name: "stories_user_id_fk"
    # add_foreign_key "suggested_taggings", "stories", name: "suggested_taggings_story_id_fk"
    # add_foreign_key "suggested_taggings", "tags", name: "suggested_taggings_tag_id_fk"
    # add_foreign_key "suggested_taggings", "users", name: "suggested_taggings_user_id_fk"
    # add_foreign_key "suggested_titles", "stories", name: "suggested_titles_story_id_fk"
    # add_foreign_key "suggested_titles", "users", name: "suggested_titles_user_id_fk"
    # add_foreign_key "tag_filters", "tags", name: "tag_filters_tag_id_fk"
    # add_foreign_key "tag_filters", "users", name: "tag_filters_user_id_fk"
    add_foreign_key "taggings", "stories", name: "taggings_story_id_fk"
    add_foreign_key "taggings", "tags", name: "taggings_tag_id_fk", on_update: :cascade, on_delete: :cascade
    # add_foreign_key "users", "users", column: "banned_by_user_id", name: "users_banned_by_user_id_fk"
    # add_foreign_key "users", "users", column: "disabled_invite_by_user_id", name: "users_disabled_invite_by_user_id_fk"
    # add_foreign_key "users", "users", column: "invited_by_user_id", name: "users_invited_by_user_id_fk"
    add_foreign_key "votes", "comments", name: "votes_comment_id_fk", on_update: :cascade, on_delete: :cascade
    add_foreign_key "votes", "stories", name: "votes_story_id_fk"
    add_foreign_key "votes", "users", name: "votes_user_id_fk"
  end
end
