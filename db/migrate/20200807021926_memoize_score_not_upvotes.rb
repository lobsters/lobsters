class MemoizeScoreNotUpvotes < ActiveRecord::Migration[6.0]
  def up
    remove_index :comments, name: :downvote_index
    rename_column :comments, :upvotes, :score
    change_column :comments, :downvotes, :integer, default: 1, null: false, unsigned: true
    rename_column :comments, :downvotes, :flags
    ActiveRecord::Base.connection.execute <<~SQL
      update comments
      set score = coalesce((
        select sum(vote)
        from votes
        where comment_id = comments.id
      ), 0)
    SQL
    ActiveRecord::Base.connection.execute <<~SQL
      update comments
      set flags = coalesce((
        select count(vote)
        from votes
        where comment_id = comments.id
          and vote = -1
      ), 0)
    SQL
    add_index :comments, :score

    rename_column :stories, :upvotes, :score
    change_column :stories, :score, :integer, default: 1, null: false
    rename_column :stories, :downvotes, :flags
    ActiveRecord::Base.connection.execute <<~SQL
      update stories
      set score = coalesce((
        select sum(vote)
        from votes
        where story_id = stories.id and comment_id is null
      ), 0)
    SQL
    ActiveRecord::Base.connection.execute <<~SQL
      update stories
      set flags = coalesce((
        select count(vote)
        from votes
        where story_id = stories.id and comment_id is null
          and vote = -1
      ), 0)
    SQL
    add_index :stories, :score

    replace_view :replying_comments, version: 9
  end

  # yeah, it's not technically irreversible, but I didn't want to write this
  # whole dang thing twice when it's going to take an hour+ to see it work
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
