class RemoveHasBeenReadFromMessages < ActiveRecord::Migration[8.0]
  def change
    remove_column :messages, :has_been_read, :boolean
  end
end
