class AddHatRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :hat_requests do |t|
      t.timestamps
      t.integer :user_id
      t.string :hat, collation: "utf8mb4_general_ci"
      t.string :link, collation: "utf8mb4_general_ci"
      t.text :comment, collation: "utf8mb4_general_ci"
    end
  end
end
