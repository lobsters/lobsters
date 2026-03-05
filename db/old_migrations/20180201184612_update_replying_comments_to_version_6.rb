class UpdateReplyingCommentsToVersion6 < ActiveRecord::Migration[5.0]
  def change
    update_view :replying_comments, version: 6, revert_to_version: 5
  end
end
