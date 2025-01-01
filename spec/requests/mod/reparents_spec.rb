# typed: false

require "rails_helper"

describe "Mod::ReparentsController", type: :request do
  context "/new form" do
    it "loads" do
      sign_in create(:user, :admin)
      reparent_user = create(:user)
      get "/mod/reparents/new", params: {id: reparent_user.username}
      expect(response).to be_successful
    end
  end

  context "reparenting" do
    it "reparents the user and logs it" do
      sign_in create(:user, :admin)
      inviter = create(:user)
      reparent_user = create(:user, invited_by_user: inviter)
      post "/mod/reparents", params: {id: reparent_user.username, reason: "Abuse"}
      expect(response).to redirect_to user_path(reparent_user)
      reparent_user.reload
      expect(reparent_user.invited_by_user).to_not be(inviter)
      expect(Moderation.last.reason).to include("Abuse")
    end
  end
end
