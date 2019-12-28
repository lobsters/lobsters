require 'rails_helper'

describe 'settings', type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'GET /settings/2fa' do
    it 'returns successfully' do
      get "/settings/2fa"
      expect(response).to be_successful
    end
  end

  describe 'GET /settings/2fa_enroll' do
    before do
      post "/settings/2fa_auth",
           params: { user: { password: user.password } }
    end

    it 'returns successfully' do
      get "/settings/2fa_enroll"
      expect(response).to be_successful
      expect(session[:totp_secret]).not_to be_nil
      expect(session[:totp_secret]).to have_attributes(length: 32)
    end
  end
end
