class UpdateReplyingCommentsToVersion5 < ActiveRecord::Migration[6.0]
  def change
    update_view :replying_comments, version: 5, revert_to_version: 4
  end
end
