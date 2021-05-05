class UniqueCategoryNames < ActiveRecord::Migration[6.0]
  def change
    add_index :categories, :category, unique: true
  end
end
