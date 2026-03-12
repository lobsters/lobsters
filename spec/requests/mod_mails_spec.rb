require "rails_helper"

RSpec.describe "/mod_mails", type: :request do
  let(:mod_mail_message) { create :mod_mail_message }
  let(:mod_mail) { mod_mail_message.mod_mail }

  # BUG: if a spec forgets to call sign_in, the request hands indefinitely rather than return a
  # failure

  describe "GET /index" do
    it "shows modmails" do
      sign_in mod_mail.recipients.first
      get mod_mails_path
      expect(response).to be_successful
      expect(response.body).to include(mod_mail.subject)
    end
  end

  describe "GET /show" do
    it "shows to recipient" do
      sign_in mod_mail.recipients.first
      get mod_mail_url(mod_mail)
      expect(response).to be_successful
    end

    it "denies access to non-recipient" do
      sign_in create(:user)
      get mod_mail_url(mod_mail)
      expect(response).to redirect_to :root
    end

    it "shows to mods" do
      sign_in create(:user, :moderator)
      get mod_mail_url(mod_mail)
      expect(response).to be_successful
    end
  end
end
