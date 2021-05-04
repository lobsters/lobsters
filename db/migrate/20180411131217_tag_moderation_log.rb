class TagModerationLog < ActiveRecord::Migration[6.0]
  def change
    add_column :moderations, :tag_id, :integer, null: true, default: nil
  end
end
