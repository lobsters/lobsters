class DropStoryTextsCreatedAtDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :story_texts, :created_at, from: -> { "now()" }, to: nil
  end
end
