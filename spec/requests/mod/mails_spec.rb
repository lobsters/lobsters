require "rails_helper"

RSpec.describe "/mod/mails", type: :request do
  let(:mod_mail) { create :mod_mail }
  let(:user) { create(:user, :moderator) }

  before do
    sign_in user
  end

  describe "GET /index" do
    it "renders a successful response" do
      create :mod_mail
      get mod_mod_mails_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    before { get mod_mod_mail_url(mod_mail) }

    it "renders a successful response" do
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_mod_mod_mail_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      get edit_mod_mod_mail_url(mod_mail)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ModMail", :aggregate_failures do
        expect {
          post mod_mod_mails_url, params: {mod_mail: {subject: "No more Spam, thx", recipient_usernames: create(:user).username}}
        }.to change(ModMail, :count).by(1)
        expect(response).to redirect_to(mod_mod_mail_url(ModMail.find_by(subject: "No more Spam, thx")))
      end
    end

    context "with invalid parameters" do
      it "does not create a new ModMail", :aggregate_failures do
        expect {
          post mod_mod_mails_url, params: {mod_mail: {subject: "Message to a username that doesn't exist", recipient_usernames: "chaelcodes"}}
        }.to change(ModMail, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      it "updates the requested mod_mail", :aggregate_failures do
        patch mod_mod_mail_url(mod_mail), params: {mod_mail: {subject: "New Subject for Moderation", recipient_usernames: mod_mail.recipients.first.username}}
        mod_mail.reload

        expect(mod_mail.subject).to eq "New Subject for Moderation"
        expect(response).to redirect_to(mod_mod_mail_url(mod_mail))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        patch mod_mod_mail_url(mod_mail), params: {mod_mail: {subject: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
