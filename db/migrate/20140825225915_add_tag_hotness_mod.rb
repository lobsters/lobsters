class AddTagHotnessMod < ActiveRecord::Migration
  def change
    add_column :tags, :hotness_mod, :integer, :default => 0
  end
end
