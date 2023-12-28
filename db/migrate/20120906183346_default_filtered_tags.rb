class DefaultFilteredTags < ActiveRecord::Migration[7.1]
  def up
    add_column :tags, :filtered_by_default, :boolean, default: false
  end

  def down
  end
end
