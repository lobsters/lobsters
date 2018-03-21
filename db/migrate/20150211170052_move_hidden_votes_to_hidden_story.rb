class MoveHiddenVotesToHiddenStory < ActiveRecord::Migration[5.1]
  def up
    create_table :hidden_stories do |t|
      t.integer :user_id
      t.integer :story_id
    end

    add_index "hidden_stories", ["user_id", "story_id"], :unique => true

    Vote.where(:vote => 0).each do |v|
      hs = HiddenStory.new
      hs.user_id = v.user_id
      hs.story_id = v.story_id
      hs.save!
    end

    Vote.where(:vote => 0).delete_all
  end
end
