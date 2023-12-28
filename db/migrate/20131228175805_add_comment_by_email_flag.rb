class AddCommentByEmailFlag < ActiveRecord::Migration[7.1]
  def up
    add_column :comments, :is_from_email, :boolean, default: false
  end

  def down
  end
end
