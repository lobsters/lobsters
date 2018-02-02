class DeleteOldSettings < ActiveRecord::Migration[5.1]
  def change
    [
      :email_notifications,
      :email_replies,
      :pushover_replies,
      :pushover_user_key,
      :email_messages,
      :pushover_messages,
      :email_mentions,
      :show_avatars,
      :show_story_previews,
      :show_submitted_story_threads,
    ].each do |col|
      remove_column :users, "old_#{col}"
    end
  end
end
