class CreateMastodonInstances < ActiveRecord::Migration[7.0]
  def change
    create_table :mastodon_instances do |t|
      t.string :name, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false

      t.timestamps
    end

    add_index :mastodon_instances, :name, unique: true
  end
end
