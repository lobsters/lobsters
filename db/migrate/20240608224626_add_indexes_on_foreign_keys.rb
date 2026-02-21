class AddIndexesOnForeignKeys < ActiveRecord::Migration[7.1]
  def change
    add_index :moderations, :category_id
    add_index :messages, :author_user_id
    add_index :domains, :banned_by_user_id
  end
end
