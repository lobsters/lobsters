class MoreIndexes < ActiveRecord::Migration[5.1]
  def up
    add_index :stories, [ "is_expired", "is_moderated" ],
      :name => "is_idxes"
    add_index :tag_filters, [ "user_id", "tag_id" ],
      :name => "user_tag_idx"
  end

  def down
  end
end
