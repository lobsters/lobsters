class DropDefaultTagName < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:tags, :tag, from: '', to: nil)
  end
end
