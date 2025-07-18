class RemoveReplyingComment < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.connection.execute <<~SQL
      drop view replying_comments;
    SQL

    ActiveRecord::Base.connection.execute <<~SQL
      delete from keystores where `key` like 'user:%:unread_messages' or `key` like 'user:%:unread_replies';
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
