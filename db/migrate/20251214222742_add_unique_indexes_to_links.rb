class AddUniqueIndexesToLinks < ActiveRecord::Migration[8.0]
  INDEXES_PARAMS = [
    [:links, [:url, :from_story_id, :from_comment_id], {unique: true, name: "index_links_on_url_and_from_story_id_and_from_comment_id"}],
    [:links, [:to_comment_id, :from_story_id, :from_comment_id], {unique: true, name: "idx_links_on_to_comment_id_and_from_story_id_and_from_comment_id"}],
    [:links, [:to_story_id, :from_story_id, :from_comment_id], {unique: true, name: "index_links_on_to_story_id_and_from_story_id_and_from_comment_id"}]
  ]

  def up
    INDEXES_PARAMS.each do |table, columns, options|
      unless index_exists?(table, columns)
        add_index(table, columns, **options)
      end
    end

    remove_index :links, column: :to_comment_id if index_exists?(:links, :to_comment_id)
    remove_index :links, column: :to_story_id if index_exists?(:links, :to_story_id)
  end

  def down
    add_index :links, :to_comment_id unless index_exists?(:links, :to_comment_id)
    add_index :links, :to_story_id unless index_exists?(:links, :to_story_id)

    INDEXES_PARAMS.each do |table, columns, options|
      if index_exists?(table, columns)
        remove_index(table, columns)
      end
    end
  end
end
