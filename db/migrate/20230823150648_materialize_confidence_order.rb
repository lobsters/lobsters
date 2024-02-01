class MaterializeConfidenceOrder < ActiveRecord::Migration[7.0]
  def up
    add_column :comments, :confidence_order, "binary(3)", null: true, after: :story_id
    ActiveRecord::Base.connection.execute <<~SQL
      UPDATE comments
      SET confidence_order =
        concat(lpad(char(65536 - floor(((confidence - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(id & 0xff using binary));
    SQL
    change_column_null :comments, :confidence_order, false
  end

  def down
    remove_column :stories, :confidence_order
  end
end
