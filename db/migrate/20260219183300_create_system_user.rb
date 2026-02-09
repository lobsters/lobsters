class CreateSystemUser < ActiveRecord::Migration[8.0]
  def up
    User.create!(username: "System", email: "system@#{Rails.application.domain}", password: "test", about: "This is an account for messages from the system.")
  end

  def down
    User.where(username: "System").destroy_all
  end
end
