class CreateReadRibbons < ActiveRecord::Migration[5.1]
  def change
    create_table :read_ribbons do |t|
#      t.belongs_to :user, foreign_key: true
#      t.belongs_to :story, foreign_key: true
      t.boolean :is_following, default: true

      t.timestamps
    end
  end
end
