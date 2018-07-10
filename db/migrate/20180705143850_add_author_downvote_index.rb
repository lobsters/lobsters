class AddAuthorDownvoteIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :comments, [:user_id, :story_id, :downvotes, :created_at], name: 'downvote_index'
  end
end
