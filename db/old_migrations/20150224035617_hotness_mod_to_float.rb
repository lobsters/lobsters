class HotnessModToFloat < ActiveRecord::Migration
  def change
    change_column :tags, :hotness_mod, :float
  end
end
