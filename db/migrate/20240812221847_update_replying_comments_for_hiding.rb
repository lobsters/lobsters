class UpdateReplyingCommentsForHiding < ActiveRecord::Migration[7.1]
  def change
    replace_view :replying_comments, version: 10, revert_to_version: 9
  end
end
