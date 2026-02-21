class MaterializeCommentsDepthReplyCount < ActiveRecord::Migration[8.0]
  def change
    change_table :comments, bulk: true do
      add_column :comments, :depth, :integer, default: 0, null: false
      add_column :comments, :reply_count, :integer, default: 0, null: false
      add_column :comments, :last_reply_at, :datetime, null: true, default: nil
    end

    Comment.update_all("reply_count = (select count(*) from comments as c_inner where c_inner.parent_comment_id = comments.id)")
    Comment.update_all("last_reply_at = (select max(created_at) from comments as c_inner where c_inner.parent_comment_id = comments.id)")

    i = 0
    Comment.where.not(parent_comment_id: nil).order(:id).find_each do |comment|
      comment.update_column :depth, Comment.where(id: comment.parent_comment_id).pick(:depth) + 1
      i += 1
      Rails.logger.debug { "#{i} " } if i % 1000 == 0
    end
    Rails.logger.debug
  end

  def down
    change_table :comments, bulk: true do
      remove_column :comments, :depth
      remove_column :comments, :reply_count
      remove_column :comments, :last_reply_at
    end
  end
end
