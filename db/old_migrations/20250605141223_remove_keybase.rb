class RemoveKeybase < ActiveRecord::Migration[8.0]
  def change
    User.where("settings like '%keybase_signatures%'").find_each do |user|
      user.settings.delete :keybase_signatures
      user.save!
    end
  end
end
