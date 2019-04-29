class HotnessModToFloat < ActiveRecord::Migration[4.2]
  def change
    change_column :tags, :hotness_mod, :float
  end
end
