class TimestampVotes < ActiveRecord::Migration[5.1]
  def change
    add_column :votes, :updated_at, :datetime, null: true
    ActiveRecord::Base.connection.execute("update votes set updated_at = comments.created_at from comments where comments.id = comment_id and votes.updated_at is null")
    ActiveRecord::Base.connection.execute("update votes set updated_at = stories.created_at from stories where stories.id = story_id   and votes.updated_at is null")
    change_column_null :votes, :updated_at, false
  end
end
