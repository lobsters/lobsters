class PushoverSound < ActiveRecord::Migration
  def change
    add_column :users, :pushover_sound, :string
  end
end
