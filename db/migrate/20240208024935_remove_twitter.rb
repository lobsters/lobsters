class RemoveTwitter < ActiveRecord::Migration[7.1]
  def change
    User.where("settings like '%twitter_%'").find_each do |user|
      user.settings.delete :twitter_oauth_token
      user.settings.delete :twitter_oauth_token_secret
      user.settings.delete :twitter_username
      user.save!
    end
    remove_index :stories, :twitter_id
  end
end
