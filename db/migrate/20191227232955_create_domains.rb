class CreateDomains < ActiveRecord::Migration[6.0]
  def change
    create_table :domains do |t|
      t.string :domain, unique: true
      t.boolean :is_tracker, default: false, null: false

      t.timestamps
    end
  end
end
