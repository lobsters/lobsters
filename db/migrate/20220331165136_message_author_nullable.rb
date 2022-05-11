class MessageAuthorNullable < ActiveRecord::Migration[6.1]
  def up
    change_column_null :messages, :author_user_id, true
    Story.connection.execute("UPDATE messages SET author_user_id = NULL WHERE author_user_id = 0")
  end

  def down
    Story.connection.execute("UPDATE messages SET author_user_id = 0 WHERE author_user_id IS NULL")
    change_column_null :messages, :author_user_id, false
  end
end
