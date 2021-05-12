class InactiveTags < ActiveRecord::Migration[6.0]
  def change
    add_column :tags, :inactive, :boolean, :default => false
  end
end
