require "rails_helper"

RSpec.describe "/mod/mail_messages", type: :request do
  let(:user) { create :user }
  let(:mod_mail) { create :mod_mail, recipients: [user] }

  let(:valid_attributes) {
    {
      mod_mail_id: mod_mail.id,
      message: "I'm allowed to be a jerk if I'm right enough."
    }
  }

  let(:invalid_attributes) {
    {
      mod_mail_id: mod_mail.id
    }
  }

  before {
    sign_in user
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

      it "doesn't allow posting to others' modmails" do
        other_mm = create(:mod_mail)

        expect {
          expect {
            post mod_mail_messages_url, params: {mod_mail_message: {
              mod_mail_id: other_mm.id,
              message: "How are you gentlemen !!"
            }}
          }.to raise_error(ActiveRecord::RecordNotFound)
        }.not_to change(ModMailMessage, :count)
      end
    end
  end
end
