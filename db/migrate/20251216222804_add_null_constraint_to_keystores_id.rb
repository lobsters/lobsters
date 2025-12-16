class AddNullConstraintToKeystoresId < ActiveRecord::Migration[8.0]
  def change
    change_column_null :keystores, :id, false
  end
end
