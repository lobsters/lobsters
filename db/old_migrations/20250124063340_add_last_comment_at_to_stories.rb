class AddLastCommentAtToStories < ActiveRecord::Migration[8.0]
  def up
    add_column :stories, :last_comment_at, :datetime
    add_index :stories, :last_comment_at

    # Add SQL to populate the field for all old stories
    # that have comments. This is a backfill operation.
    ActiveRecord::Base.connection.execute <<~SQL
      UPDATE stories
      JOIN (
        SELECT story_id, MAX(created_at) AS max_created_at
        FROM comments
        GROUP BY story_id
      ) subquery
      ON stories.id = subquery.story_id
      SET stories.last_comment_at = subquery.max_created_at;
    SQL
  end

  def down
    remove_index :stories, :last_comment_at
    remove_column :stories, :last_comment_at
  end
end
