class MarkReadNotifications < ActiveRecord::Migration[8.0]
  def up
    # Set any unread notifications belonging to a read message, to read status
    ActiveRecord::Base.connection.execute <<~SQL
      update notifications
      join messages
      on notifications.notifiable_type = 'Message' and notifications.notifiable_id = messages.id
      set notifications.read_at = now()
      where notifications.read_at = null
      and messages.has_been_read;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
