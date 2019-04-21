require "rails_helper"

RSpec.describe ConversationCreator do
  describe "#create" do
    it "creates a conversation" do
      expect(Conversation.count).to eq(0)

      creator = ConversationCreator.new

      creator.create(
        author: create(:user),
        recipient_username: create(:user).username,
        subject: "this is a subject",
        message_params: { body: "this is the body" },
      )

      expect(Conversation.count).to eq(1)
    end

    it "uses the MessageCreator to create an associated message" do
      allow(MessageCreator).to receive(:create)
      creator = ConversationCreator.new
      author = create(:user)
      recipient_username = create(:user).username

      conversation = creator.create(
        author: author,
        recipient_username: recipient_username,
        subject: "this is a subject",
        message_params: { body: "this is the body" },
      )

      expect(MessageCreator).to have_received(:create).with(
        conversation: conversation,
        author: author,
        body: "this is the body",
        hat_id: nil,
      )
    end
  end
end
