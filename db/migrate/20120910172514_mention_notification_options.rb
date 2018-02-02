class MentionNotificationOptions < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :email_mentions, :boolean, :default => false
    add_column :users, :pushover_mentions, :boolean, :default => false
  end

  def down
    remove_column :users, :pushover_mentions
    remove_column :users, :email_mentions
  end
end
