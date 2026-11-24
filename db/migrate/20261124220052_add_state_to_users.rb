class AddStateToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :state, :string, null: false, default: "new"

    User.reset_column_information
    User.find_each(batch_size: 1000) do |user|
      user.update_column(:state, user.implicit_state)
    end

    User.find_by(username: "System")&.update_column(:state, "system")
    User.find_by(username: "inactive-user")&.update_column(:state, "system")
  end

  def down
    remove_column :users, :state
  end
end
