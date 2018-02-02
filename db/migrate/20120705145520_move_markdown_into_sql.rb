class MoveMarkdownIntoSql < ActiveRecord::Migration[5.1]
  def up
    add_column :comments, :markeddown_comment, :text
    add_column :stories, :markeddown_description, :text

    Comment.all.each do |c|
      c.markeddown_comment = c.generated_markeddown_comment
      Comment.record_timestamps = false
      c.save(:validate => false)
    end

    Story.all.each do |s|
      if s.description.present?
        s.markeddown_description = s.generated_markeddown_description
        Story.record_timestamps = false
        s.save(:validate => false)
      end
    end
  end

  def down
  end
end
