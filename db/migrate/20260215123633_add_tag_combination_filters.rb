# typed: false

class AddTagCombinationFilters < ActiveRecord::Migration[8.0]
  def up
    # tag_hash on stories for bloom filter lookups
    add_column :stories, :tag_hash, :bigint, default: 0, null: false
    add_index :stories, :tag_hash

    # backfill last 90 days
    cutoff_date = 90.days.ago
    Story.where("created_at > ?", cutoff_date).includes(:tags).find_in_batches(batch_size: 1000) do |batch|
      batch.each do |story|
        h = story.tags.reduce(0) { |acc, tag| acc | (1 << (tag.id % 64)) }
        h = h >= 2**63 ? h - 2**64 : h
        story.update_column(:tag_hash, h)
      end
    end

    # combo filter tables
    create_table :tag_filter_combinations, id: :bigint, unsigned: true do |t|
      t.bigint :user_id, null: false, unsigned: true, index: true
      t.bigint :combo_hash, null: false
      t.integer :tag_count, null: false
      t.timestamps
    end

    add_foreign_key :tag_filter_combinations, :users
    add_index :tag_filter_combinations, :combo_hash
    add_index :tag_filter_combinations, [:user_id, :updated_at]

    create_table :tag_filter_combination_tags, id: :bigint, unsigned: true do |t|
      t.bigint :tag_filter_combination_id, null: false, unsigned: true, index: true
      t.bigint :tag_id, null: false, unsigned: true, index: true
      t.timestamps
    end

    add_foreign_key :tag_filter_combination_tags, :tag_filter_combinations
    add_foreign_key :tag_filter_combination_tags, :tags
    add_index :tag_filter_combination_tags,
      [:tag_filter_combination_id, :tag_id],
      unique: true,
      name: "index_combination_tags_unique"
  end

  def down
    drop_table :tag_filter_combination_tags
    drop_table :tag_filter_combinations
    remove_index :stories, :tag_hash
    remove_column :stories, :tag_hash
  end
end
