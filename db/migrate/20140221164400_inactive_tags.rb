class InactiveTags < ActiveRecord::Migration[7.1]
  def change
    add_column :tags, :inactive, :boolean, default: false
  end
end
