class CreateReplyingComments < ActiveRecord::Migration[5.0]
  def change
    create_view :replying_comments
  end
end
