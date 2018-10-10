class AddInvitationRequests < ActiveRecord::Migration[4.2]
  def up
    create_table :invitation_requests, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
      t.string :code
      t.boolean :is_verified, :default => false
      t.string :email
      t.string :name
      t.text :memo
      t.string :ip_address
      t.timestamps :null => false
    end
  end

  def down
    drop_table :invitation_requests
  end
end
