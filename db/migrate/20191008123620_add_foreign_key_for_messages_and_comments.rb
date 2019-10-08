class AddForeignKeyForMessagesAndComments < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        execute "ALTER TABLE messages ADD FOREIGN KEY (author_user_id) REFERENCES users(id);"
      end

      dir.down do
        remove_foreign_key :messages, :users
      end
    end
  end
end
