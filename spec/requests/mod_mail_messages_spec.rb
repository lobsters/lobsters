require "rails_helper"

RSpec.describe "/mod/mail_messages", type: :request do
  let(:user) { create :user }
  let(:moderator) { create :user, :moderator }
  let(:mod_mail) { create :mod_mail, recipients: [user] }

  let(:valid_attributes) {
    {
      mod_mail_id: mod_mail.id,
      message: "I have concerns about your recent behavior.",
      user_id: moderator.id
    }
  }

  let(:invalid_attributes) {
    {
      mod_mail_id: mod_mail.id,
      user_id: moderator.id
    }
  }

  before {
    sign_in moderator
  }

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ModMailMessage" do
        expect {
          post mod_mail_messages_url, params: {mod_mail_message: valid_attributes}
        }.to change(ModMailMessage, :count).by(1)
      end

      it "redirects to the created mod_mail_message" do
        post mod_mail_messages_url, params: {mod_mail_message: valid_attributes}
        expect(response).to redirect_to(mod_mail_url(mod_mail))
        expect(NotifyModMailMessageJob).to have_been_enqueued.exactly(:once)
      end
    end

    context "with invalid parameters" do
      it "does not create a new ModMailMessage" do
        expect {
          post mod_mail_messages_url, params: {mod_mail_message: invalid_attributes}
        }.to change(ModMailMessage, :count).by(0)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        post mod_mail_messages_url, params: {mod_mail_message: invalid_attributes}
        expect(response).to redirect_to mod_mail
      end
    end
  end
end
