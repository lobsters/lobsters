class MoveCommentCountsToStory < ActiveRecord::Migration[5.1]
  def up
    add_column :stories, :comments_count, :integer, :default => 0,
      :null => false

    Keystore.transaction do
      Story.lock(true).select(:id).each do |s|
        s.update_comments_count!
      end

      Keystore.where(
        Keystore.arel_table[:key].matches("story:%:comment_count")).delete_all
    end
  end

  def down
    Keystore.transaction do
      Story.select(:id).each do |s|
        s.update_comments_count!
      end
    end

    remove_column :stories, :comments_count
  end
end
