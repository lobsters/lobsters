class DefaultFilteredTags < ActiveRecord::Migration[4.2]
  def up
    add_column :tags, :filtered_by_default, :boolean, :default => false
  end

  def down
  end
end
