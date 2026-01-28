class AddLastReadLineToNewest < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :last_read_newest, :datetime, null: true, default: nil
  end
end
