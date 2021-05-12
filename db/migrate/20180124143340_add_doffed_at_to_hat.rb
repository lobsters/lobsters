class AddDoffedAtToHat < ActiveRecord::Migration[6.0]
  def change
    add_column :hats, :doffed_at, :datetime, null: true, default: nil
    change_column :hats, :hat, :string, null: false, default: nil
  end
end
