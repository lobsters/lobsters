class PmNotificationOptions < ActiveRecord::Migration[5.1]
  def up
    change_table :messages do |t|
      t.change :has_been_read, :boolean, :default => false
    end

    add_column :users, :email_messages, :boolean, :default => true
    add_column :users, :pushover_messages, :boolean, :default => true
  end

  def down
  end
end
