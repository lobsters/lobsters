require 'rails_helper'

RSpec.describe "/mod/mails", type: :request do
  let(:mod) { create(:user, :moderator) }
  let(:recipient) { create :user }
  let(:user) { mod }
  let(:valid_attributes) do
    {
      subject: "Moderation Mail Subject",
      recipients: [recipient]
    }
  end

  let(:invalid_attributes) do
    {
      subject: "invalid username that does not exist",
      recipient_usernames: "chaelcodes"
    }
  end

  before do
    sign_in user
  end

  describe "GET /index" do
    it "renders a successful response" do
      ModMail.create! valid_attributes
      get mod_mails_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    let(:mod_mail) { ModMail.create! valid_attributes }

    before { get mod_mail_url(mod_mail) }

    it "renders a successful response" do
      expect(response).to be_successful
    end

    context "when recipient" do
      let(:user) { recipient }

      it "shows the recipient the mod mail" do
        expect(response).to be_successful
      end
    end

    context "when not mod nor recipient" do
      let(:user) { create :user }

      it "does not show random user the mod mail" do
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_mod_mail_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      mod_mail = ModMail.create! valid_attributes
      get edit_mod_mail_url(mod_mail)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ModMail" do
        expect {
          post mod_mails_url, params: { mod_mail: valid_attributes.merge(recipient_usernames: recipient.username) }
        }.to change(ModMail, :count).by(1)
      end

      it "redirects to the created mod_mail" do
        post mod_mails_url, params: { mod_mail: valid_attributes.merge(recipient_usernames: recipient.username) }
        expect(response).to redirect_to(mod_mail_url(ModMail.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new ModMail" do
        expect {
          post mod_mails_url, params: { mod_mail: invalid_attributes }
        }.to change(ModMail, :count).by(0)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post mod_mails_url, params: { mod_mail: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        {
          subject: "New Subject for Moderation"
        }
      }

      it "updates the requested mod_mail" do
        mod_mail = ModMail.create! valid_attributes
        patch mod_mail_url(mod_mail), params: { mod_mail: new_attributes }
        mod_mail.reload

        expect(mod_mail.subject).to eq "New Subject for Moderation"
      end

      it "redirects to the mod_mail" do
        mod_mail = ModMail.create! valid_attributes
        patch mod_mail_url(mod_mail), params: { mod_mail: new_attributes }
        mod_mail.reload
        expect(response).to redirect_to(mod_mail_url(mod_mail))
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status (i.e. to display the 'edit' template)" do
        mod_mail = ModMail.create! valid_attributes
        patch mod_mail_url(mod_mail), params: { mod_mail: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
