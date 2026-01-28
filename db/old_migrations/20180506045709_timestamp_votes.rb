class TimestampVotes < ActiveRecord::Migration[5.1]
  def change
    add_column :votes, :updated_at, :datetime, null: true
    ActiveRecord::Base.connection.execute("update votes, comments set votes.updated_at = comments.created_at where comments.id = votes.comment_id and votes.updated_at is null")
    ActiveRecord::Base.connection.execute("update votes, stories  set votes.updated_at = stories.created_at  where stories.id  = votes.story_id   and votes.updated_at is null")
    change_column_null :votes, :updated_at, false
  end
end
