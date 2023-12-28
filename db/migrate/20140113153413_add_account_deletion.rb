class AddAccountDeletion < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :deleted_at, :datetime
  end
end
