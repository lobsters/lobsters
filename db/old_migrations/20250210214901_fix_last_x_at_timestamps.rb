class FixLastXAtTimestamps < ActiveRecord::Migration[8.0]
  def change
    Story.update_all("last_comment_at = (select max(last_edited_at) from comments where story_id = stories.id)")
    Comment.update_all("last_reply_at = (select max(created_at) from comments as c_inner where c_inner.parent_comment_id = comments.id)")
  end
end
