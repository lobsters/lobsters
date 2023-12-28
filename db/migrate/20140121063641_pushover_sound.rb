class PushoverSound < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :pushover_sound, :string
  end
end
