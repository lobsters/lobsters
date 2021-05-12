class AddDomainBanning < ActiveRecord::Migration[6.0]
  def change
    add_column :domains, :banned_at, :datetime, null: true, default: nil
    add_column :domains, :banned_by_user_id, :integer, null: true, default: nil
    add_column :domains, :banned_reason, :string, :limit => 200
    add_column :moderations, :domain_id, :integer, null: true, default: nil
    add_index :moderations, :domain_id
  end
end
