class DropDefaultTagName < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:tags, :tag, from: '', to: nil)
  end
end
