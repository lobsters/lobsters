class PushoverSound < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :pushover_sound, :string
  end
end
