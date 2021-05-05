class AddTagHotnessMod < ActiveRecord::Migration[6.0]
  def change
    add_column :tags, :hotness_mod, :integer, :default => 0
  end
end
