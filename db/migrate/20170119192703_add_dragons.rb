class AddDragons < ActiveRecord::Migration
  def change
    add_column :comments, :is_dragon, :boolean, :default => false
  end
end
