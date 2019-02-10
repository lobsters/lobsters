class AddOwnerToApplication < ActiveRecord::Migration[5.1]
    def change
      add_column :oauth_applications, :owner_id, :integer, null: true
      add_column :oauth_applications, :owner_type, :string, null: true
      add_index :oauth_applications, [:owner_id, :owner_type]
    end
end