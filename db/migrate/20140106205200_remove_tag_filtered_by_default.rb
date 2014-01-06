class RemoveTagFilteredByDefault < ActiveRecord::Migration
  def change
    remove_column :tags, :filtered_by_default
  end
end
