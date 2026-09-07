require "rails_helper"

describe SettingsController do
  describe "update" do
    let(:user) { create(:user) }

    it "records a moderation log when the username changes" do
      old_username = user.username
      new_username = "#{user.username}0"
      user.usernames.touch_all(:created_at, time: 2.years.ago) # needed to pass User#validate_username_timeouts
      stub_login_as user
      expect { post :update, params: {user: {password: "", username: new_username}} }.to change(Moderation, :count).by(1)
      expect(response.status).to eq(200)
      user.reload
      expect(user.username).to eq(new_username)
      moderation = Moderation.last
      expect(moderation.is_from_suggestions).to eq(true)
      expect(moderation.moderator_user_id).to be_nil
      expect(moderation.user).to eq(user)
      expect(moderation.action).to eq("changed own username from \"#{old_username}\" to \"#{new_username}\"")
    end
  end
end
