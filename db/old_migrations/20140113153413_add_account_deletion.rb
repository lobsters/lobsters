class AddAccountDeletion < ActiveRecord::Migration
  def change
    add_column :users, :deleted_at, :datetime
  end
end
