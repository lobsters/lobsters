require "rails_helper"

RSpec.describe "/mod/mail_messages", type: :request do
  let(:moderator) { create :user, :moderator }
  let(:mod_mail) { create :mod_mail }

  before {
    sign_in moderator
  }

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ModMailMessage", :aggregate_examples do
        expect {
          post mod_mod_mail_messages_url, params: {mod_mail_message: {message: "I've been considering my recent behavior, and you're right. It's been abysmal. I think I'll behave for exactly one month and then start it up again.", mod_mail_id: mod_mail.id}}
        }.to change(ModMailMessage, :count).by(1)
        expect(response).to redirect_to(mod_mod_mail_url(mod_mail))
        expect(NotifyModMailMessageJob).to have_been_enqueued.exactly(:once)
      end
    end

    context "with invalid parameters" do
      it "does not create a new ModMailMessage" do
        expect {
          post mod_mod_mail_messages_url, params: {mod_mail_message: {message: "short message", mod_mail_id: mod_mail.id}}
        }.to change(ModMailMessage, :count).by(0)
        expect(response).to redirect_to mod_mod_mail_url(mod_mail)
      end
    end
  end
end
