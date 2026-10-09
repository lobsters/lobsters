class FixCaseInsensitiveColumns < ActiveRecord::Migration[8.1]
  def up
    change_column :invitation_requests, :email, :string, null: false, collation: "NOCASE"
    change_column :invitations, :email, :string, collation: "NOCASE"
    change_column :usernames, :username, :string, null: false, collation: "NOCASE"
    change_column :users, :email, :string, limit: 100, collation: "NOCASE"

    execute "update domains set domain = lower(domain)"
    change_column :domains, :domain, :string, null: false, collation: "NOCASE"

    execute "update origins set identifier = lower(identifier)"
    change_column :origins, :identifier, :string, null: false, collation: "NOCASE"

    execute "update mastodon_apps set name = lower(name)"
    change_column :mastodon_apps, :name, :string, null: false, collation: "NOCASE"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
