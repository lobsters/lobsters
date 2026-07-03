class AddCustomColorToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :custom_color, :integer
  end
end
