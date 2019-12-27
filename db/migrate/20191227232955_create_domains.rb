class CreateDomains < ActiveRecord::Migration[5.2]
  def change
    create_table :domains do |t|
      t.string :fqdn, unique: true
      t.boolean :is_tracker

      t.timestamps
    end
  end
end
