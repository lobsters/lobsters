class CreateMastodonApps < ActiveRecord::Migration[7.1]
  def change
    create_table :mastodon_apps do |t|
      t.string :name, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false

      t.timestamps
    end

    add_index :mastodon_apps, :name, unique: true
  end
end
