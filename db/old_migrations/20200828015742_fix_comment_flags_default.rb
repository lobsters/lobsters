class FixCommentFlagsDefault < ActiveRecord::Migration[6.0]
  def change
    change_column :comments, :flags, :integer, default: 0, null: false, unsigned: true
    ActiveRecord::Base.connection.execute <<~SQL
      update comments
      set flags = coalesce((
        select count(vote)
        from votes
        where comment_id = comments.id
          and vote = -1
      ), 0)
    SQL
  end
end
