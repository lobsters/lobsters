class AddTagHotnessMod < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :hotness_mod, :integer, :default => 0
  end
end
