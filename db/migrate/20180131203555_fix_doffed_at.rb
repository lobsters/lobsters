class FixDoffedAt < ActiveRecord::Migration[5.1]
  def change
    change_column_default :hats, :doffed_at, nil
    Hat.where("doffed_at = ?", "0000-00-00 00:00:00").update_all(:doffed_at => nil)
  end
end
