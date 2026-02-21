class AddNocaseCollationToUsername < ActiveRecord::Migration[8.0]
  def up
    change_column :users, :username, :string, limit: 50, collation: "NOCASE"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
