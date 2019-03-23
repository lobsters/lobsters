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
        message_body: "this is the body",
      )

      expect(Conversation.count).to eq(1)
    end

    it "creates an associated message" do
      expect(Message.count).to eq(0)

      creator = ConversationCreator.new

      conversation = creator.create(
        author: create(:user),
        recipient_username: create(:user).username,
        subject: "this is a subject",
        message_body: "this is the body",
      )
      message = conversation.messages.first

      expect(Message.count).to eq(1)
      expect(message.body).to eq("this is the body")
    end
  end
end
