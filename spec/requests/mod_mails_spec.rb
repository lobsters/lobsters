require "rails_helper"

RSpec.describe "/mod_mails", type: :request do
  let(:mod_mail) { create :mod_mail }

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
