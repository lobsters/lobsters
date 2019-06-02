require "rails_helper"

RSpec.describe ConversationCreator do
  describe "#create" do
    it "creates a conversation" do
      expect(Conversation.count).to eq(0)

      author = create(:user)
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

      author = create(:user)
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
      expect(Conversation.count).to eq(0)

      author = create(:user)
      ConversationCreator.create(
        author: author,
        recipient_username: "this_user_doesnt_exist",
        subject: "this is a subject",
        message_params: { body: "this is the body" },
      )

      expect(Conversation.count).to eq(0)
    end

    it "doesn't allow invalid recipients" do
      expect(Conversation.count).to eq(0)

      author = create(:user)
      ConversationCreator.create(
        author: author,
        recipient_username: "this_user_doesnt_exist",
        subject: "this is a subject",
        message_params: { body: "this is the body" },
      )

      expect(Conversation.count).to eq(0)
    end
  end
end
