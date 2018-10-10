class AddHats < ActiveRecord::Migration[4.2]
  def change
    create_table :hats do |t|
      t.timestamps
      t.integer :user_id
      t.integer :granted_by_user_id
      t.string :hat
      t.string :link
    end

    add_column :comments, :hat_id, :integer
  end
end
