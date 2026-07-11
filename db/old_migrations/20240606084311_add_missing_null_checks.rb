class AddMissingNullChecks < ActiveRecord::Migration[7.1]
  def change
    # NULL string columns
    change_column_null :domains, :domain, false
    change_column_null :categories, :category, false

    # Booleans
    change_column_null :users, :is_admin, false
    change_column_null :users, :is_moderator, false
    change_column_null :users, :pushover_mentions, false
    change_column_null :read_ribbons, :is_following, false
    change_column_null :comments, :is_deleted, false
    change_column_null :comments, :is_moderated, false
    change_column_null :comments, :is_from_email, false
    change_column_null :moderations, :is_from_suggestions, false
    change_column_null :messages, :has_been_read, false
    change_column_null :messages, :deleted_by_author, false
    change_column_null :messages, :deleted_by_recipient, false
    change_column_null :stories, :user_is_author, false
    change_column_null :invitation_requests, :is_verified, false
    change_column_null :hats, :modlog_use, false
  end
end
