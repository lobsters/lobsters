class UniqueCategoryNames < ActiveRecord::Migration[5.2]
  def change
    add_index :categories, :category, unique: true
  end
end
