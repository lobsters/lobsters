class RemoveTagFilteredByDefault < ActiveRecord::Migration[5.1]
  def change
    remove_column :tags, :filtered_by_default
  end
end
