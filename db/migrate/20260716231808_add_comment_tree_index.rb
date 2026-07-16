class AddCommentTreeIndex < ActiveRecord::Migration[8.0]
  def up
    execute "CREATE INDEX index_comment_tree ON comments (parent_comment_id, depth + confidence, id)"
  end

  def down
    execute "DROP INDEX index_comment_tree"
  end
end
