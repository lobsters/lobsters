class AddIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :votes, [ :comment_id ]
    add_index :comments, [ :user_id ]
    add_index :stories, [ :created_at ]
  end
end
