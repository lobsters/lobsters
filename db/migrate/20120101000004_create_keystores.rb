class CreateKeystores < ActiveRecord::Migration[4.2]
  def change
    create_table :keystores do |t|
      t.bigint "value"
      t.string "key"
      t.timestamps
    end
  end
end
