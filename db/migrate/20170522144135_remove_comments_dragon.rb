class RemoveCommentsDragon < ActiveRecord::Migration[7.1]
  def change
    remove_column :comments, :is_dragon
  end
end
