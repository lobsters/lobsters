class RemoveTagFilteredByDefault < ActiveRecord::Migration[7.1]
  def change
    remove_column :tags, :filtered_by_default
  end
end
