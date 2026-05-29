class CreateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|
      t.string :url, null: false
      t.string :normalized_url, null: false
      t.index :normalized_url
      t.string :title, null: true

      t.bigint :from_story_id, null: true, index: true
      t.bigint :from_comment_id, null: true, index: true
      t.bigint :to_story_id, null: true, index: true
      t.bigint :to_comment_id, null: true, index: true
    end
  end
end
