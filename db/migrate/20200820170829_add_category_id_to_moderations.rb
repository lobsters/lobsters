class AddCategoryIdToModerations < ActiveRecord::Migration[6.0]
  def change
    add_column :moderations, :category_id, :bigint, null: true, default: nil
  end
end
