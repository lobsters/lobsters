class RemoveCommentsDragon < ActiveRecord::Migration
  def change
    remove_column :comments, :is_dragon
  end
end
