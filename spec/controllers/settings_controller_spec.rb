require 'rails_helper'

describe SettingsController do
  let(:user) { create(:user) }

  before { stub_login_as user }

  describe 'GET /settings/2fa' do
    it 'returns successfully' do
      get :twofa
      expect(response).to be_successful
    end
  end

  describe 'GET /settings/2fa_enroll' do
    it 'returns successfully' do
      get :twofa_enroll, session: { last_authed: Time.current }
      expect(response).to be_successful
      expect(session[:totp_secret]).not_to be_nil
      expect(session[:totp_secret]).to have_attributes(length: 32)
    end
  end
end
