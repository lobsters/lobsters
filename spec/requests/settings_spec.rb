# typed: false

require "rails_helper"

describe "settings", type: :request do
  let(:user) { create(:user, password: "original") }

  before { sign_in user }

  describe "updating password" do
    it "rolls session token" do
      user.password = "original"
      user.save!
      before_token = user.session_token
      post "/settings",
        params: {
          current_password: "original",
          user: {
            password: "replaced",
            password_confirmation: "replaced"
          }
        }
      user.reload
      after_token = user.session_token
      expect(after_token).to_not eq(before_token)
      expect(response.cookies["lobster_trap"]).to_not be_blank
    end
  end

  describe "GET /settings/2fa" do
    it "returns successfully" do
      get "/settings/2fa"
      expect(response).to be_successful
    end
  end

  describe "GET /settings/2fa_enroll" do
    before do
      post "/settings/2fa_auth",
        params: {user: {password: user.password}}
    end

    it "returns successfully" do
      get "/settings/2fa_enroll"
      expect(response).to be_successful
      expect(session[:totp_secret]).not_to be_nil
      expect(session[:totp_secret]).to have_attributes(length: 32)
    end
  end
end
