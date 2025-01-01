class AddHiddenStoryCreatedAt < ActiveRecord::Migration[7.1]
  def change
    add_column :hidden_stories, :created_at, :datetime, null: true
  end
end
