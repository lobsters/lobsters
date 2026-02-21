class AddStoryMastodonId < ActiveRecord::Migration[7.1]
  def change
    change_table :stories, bulk: true do |t|
      t.column :mastodon_id, :string, limit: 25, null: true
      t.index [:mastodon_id]
    end
  end
end
