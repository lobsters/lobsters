class AddNocaseCollationToCategoryAndTag < ActiveRecord::Migration[8.0]
  def change
    change_column :categories, :category, :string, limit: 25, null: false, collation: "NOCASE"
    change_column :tags, :tag, :string, limit: 25, null: false, collation: "NOCASE"
  end
end
