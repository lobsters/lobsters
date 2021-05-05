class RemoveTagFilteredByDefault < ActiveRecord::Migration[6.0]
  def change
    remove_column :tags, :filtered_by_default
  end
end
