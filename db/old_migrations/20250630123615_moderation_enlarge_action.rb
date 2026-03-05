class ModerationEnlargeAction < ActiveRecord::Migration[8.0]
  def up
    change_column :moderations, :action, :text, size: :long, null: false
  end

  def down
    change_column :moderations, :action, :text, size: :medium, null: false
  end
end
