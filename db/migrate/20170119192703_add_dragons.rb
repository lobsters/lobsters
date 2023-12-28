class AddDragons < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :is_dragon, :boolean, default: false
  end
end
