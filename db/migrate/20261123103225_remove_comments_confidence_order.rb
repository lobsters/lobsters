class RemoveCommentsConfidenceOrder < ActiveRecord::Migration[8.1]
  def up
    # still open https://github.com/rails/rails/issues/58705
    execute "alter table comments drop column confidence_order"
  end

  def down
    add_column :comments, :confidence_order, :binary, limit: 3, default: "\x00\x00\x00", null: false
  end
end
