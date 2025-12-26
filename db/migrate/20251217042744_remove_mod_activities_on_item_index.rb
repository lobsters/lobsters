# Removes an index that is redundant with another index on the same columns.
class RemoveModActivitiesOnItemIndex < ActiveRecord::Migration[8.0]
  def up
    if index_exists?(:mod_activities, [:item_type, :item_id], name: "index_mod_activities_on_item")
      remove_index :mod_activities, name: "index_mod_activities_on_item"
    end
  end

  def down
    unless index_exists?(:mod_activities, [:item_type, :item_id], name: "index_mod_activities_on_item")
      add_index :mod_activities, [:item_type, :item_id], name: "index_mod_activities_on_item"
    end
  end
end
