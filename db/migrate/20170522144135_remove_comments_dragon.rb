class RemoveCommentsDragon < ActiveRecord::Migration[4.2]
  def change
    remove_column :comments, :is_dragon
  end
end
