class ReplyNotifications < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :email_replies, :boolean, :default => false
    add_column :users, :pushover_replies, :boolean, :default => false
    add_column :users, :pushover_user_key, :string
    add_column :users, :pushover_device, :string
  end

  def down
  end
end
