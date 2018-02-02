class IntegratedStoryHotness < ActiveRecord::Migration[5.1]
  def up
    add_column :stories, :hotness, :decimal, :precision => 20, :scale => 10
    add_column :comments, :confidence, :decimal, :precision => 20, :scale => 19

    add_index :stories, [ "hotness" ], :name => "hotness_idx"
    add_index :comments, [ "confidence" ], :name => "confidence_idx"

    Comment.all.each do |c|
      c.give_upvote_or_downvote_and_recalculate_confidence!(0, 0)
    end
    
    Story.all.each do |s|
      s.give_upvote_or_downvote_and_recalculate_hotness!(0, 0)
    end
  end

  def down
  end
end
