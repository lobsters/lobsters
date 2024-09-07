# typed: false

require "rails_helper"

describe "messages", type: :request do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user) }
  let(:hat) { create(:hat, user: sender) }

  before do
    sign_in sender
  end

  context "create" do
    it "lets users send messages to each other" do
      expect {
        post "/messages", params: {
          message: {
            recipient_username: recipient.username,
            subject: "hello",
            body: "I would like to subscribe to your newsletter"
          }
        }
      }.to(change { Message.count }.by(1))

      expect(recipient.received_messages.last.subject).to eq("hello")
    end

    it "sets hats on messages" do
      post "/messages", params: {
        message: {
          recipient_username: recipient.username,
          subject: "hello",
          body: "I would like to subscribe to your newsletter",
          hat_id: hat.short_id
        }
      }
      m = recipient.received_messages.last
      expect(m.subject).to eq("hello")
      expect(m.hat).to eq(hat)
    end
  end
end
