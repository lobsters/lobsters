class AddNocaseCollationToCategoryAndTag < ActiveRecord::Migration[8.0]
  def up
    change_column :categories, :category, :string, limit: 25, null: false, collation: "NOCASE"
    change_column :tags, :tag, :string, limit: 25, null: false, collation: "NOCASE"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
