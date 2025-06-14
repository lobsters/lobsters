# typed: false

require "rails_helper"

describe MessagesController do
  let(:recipient) { create(:user) }
  let(:sender) { create(:user) }

  describe "POST create" do
    it "schedules a notification job" do
      stub_login_as sender
      post :create, params: {message: {recipient_username: recipient.username, subject: 'hello', body: 'secret message'}}
      expect(response.status).to eq(302)
      expect(NotifyJob).to have_been_enqueued.exactly(:once)
    end
  end
end
