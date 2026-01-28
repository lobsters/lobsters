class AddShortIdHats < ActiveRecord::Migration[7.1]
  def up
    add_column :hats, :short_id, :string
    Hat.find_each do |hat|
      hat.assign_short_id
      hat.save!
    end
    change_column :hats, :short_id, :string, null: false
  end

  def down
    remove_column :hats, :short_id
  end
end
