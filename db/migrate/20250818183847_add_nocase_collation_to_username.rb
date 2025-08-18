class AddNocaseCollationToUsername < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :username, :string, limit: 50, collation: "NOCASE"
  end
end
