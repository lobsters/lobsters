class PushoverSound < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :pushover_sound, :string
  end
end
