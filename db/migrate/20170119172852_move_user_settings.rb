class MoveUserSettings < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :settings, :text

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
      rename_column :users, col, "old_#{col}"
    end

    User.find_each do |u|
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
      ].each do |k|
        u.settings[k] = u.send("old_#{k}")
      end

      u.save(:validate => false)
    end
  end

  def down
    remove_column :users, :settings

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
      rename_column :users, "old#{col}", col
    end
  end
end
