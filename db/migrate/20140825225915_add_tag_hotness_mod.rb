class AddTagHotnessMod < ActiveRecord::Migration[5.1]
  def change
    add_column :tags, :hotness_mod, :integer, :default => 0
  end
end
