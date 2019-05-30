require "rails_helper"

RSpec.describe ConversationCreator do
  let(:author) { create(:user) }

  describe "#create" do
    it "creates a conversation" do
      expect(Conversation.count).to eq(0)

      ConversationCreator.create(
        author: author,
        recipient_username: create(:user).username,
        subject: "this is a subject",
        message_params: { body: "this is the body" },
      )

      expect(Conversation.count).to eq(1)
    end

    it "uses the MessageCreator to create an associated message" do
      allow(MessageCreator).to receive(:create)
      recipient_username = create(:user).username

      conversation = ConversationCreator.create(
        author: author,
        recipient_username: recipient_username,
        subject: "this is a subject",
        message_params: { body: "this is the body" },
      )

      expect(MessageCreator).to have_received(:create).with(
        conversation: conversation,
        author: author,
        params: { body: "this is the body" }
      )
    end

    it "doesn't allow invalid recipients" do
      creation_attempt = lambda do
        ConversationCreator.create(
          author: author,
          recipient_username: "this_user_doesnt_exist",
          subject: "this is a subject",
          message_params: { body: "this is the body" },
        )
      end

      expect(&creation_attempt).to_not change { Conversation.count }
    end
  end
end
