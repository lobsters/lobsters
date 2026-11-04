class CreateHotspots < ActiveRecord::Migration[8.1]
  def change
    create_table :hotspot_docs do |t|
      t.bigint :comment_id, null: false, index: {unique: true}
      t.json :terms, null: false
      t.integer :token_count, null: false
      t.boolean :bad, null: false
      t.float :logit, null: false, index: true
      t.json :matched_terms, null: false
      t.datetime :created_at, null: false
    end

    create_table :hotspot_term_counts do |t|
      t.string :term, null: false, index: {unique: true}
      t.integer :bad_doc_count, null: false
    end

    create_table :hotspot_terms do |t|
      t.string :term, null: false
      t.float :weight, null: false
    end
  end
end
