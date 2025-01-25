# typed: false

require "rails_helper"

describe "login", type: :request do
  let(:user) { create(:user, password: "asdf") }
  let(:moderator) { create(:user, :moderator, password: "asdf") }

  describe "mod-only routes" do
    it "loads for a mod" do
      sign_in user
      get "/mod"
      expect(flash[:error]).to include("authorized")
      expect(response).to redirect_to("/")
    end

    it "doesn't load for a non-mod user" do
      sign_in moderator
      get "/mod"
      expect(flash[:error]).to be_nil
      expect(response).to be_successful
    end

    # visitors hit the require_logged_in_user path first;
    # this is a more useful error for mods who are logged out
    it "doesn't load for a visitor" do
      get "/mod"
      expect(response).to redirect_to("/login")
    end
  end
end
