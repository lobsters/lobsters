class AddDragons < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :is_dragon, :boolean, :default => false
  end
end
