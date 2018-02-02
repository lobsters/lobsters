class AddHatRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :hat_requests do |t|
      t.timestamps
      t.integer :user_id
      t.string :hat
      t.string :link
      t.text :comment
    end
  end
end
