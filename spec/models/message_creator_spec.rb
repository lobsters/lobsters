require "rails_helper"

RSpec.describe MessageCreator do
  describe "#create" do
    it "creates a message on a conversation" do
      expect(Message.count).to eq(0)

      conversation = create(:conversation)

      message = MessageCreator.new.create(
        conversation: conversation,
        author: conversation.author,
        body: "Hi"
      )
      conversation.reload

      expect(Message.count).to eq(1)
      expect(conversation.messages.last).to eq(message)
    end

    it "uses the conversation subject" do
      conversation = create(:conversation, subject: "Here I am")

      message = MessageCreator.new.create(
        conversation: conversation,
        author: conversation.author,
        body: "Hi"
      )

      expect(message.subject).to eq("Here I am")
    end

    it "sets the recipient to the other person in the conversation" do
      user1 = create(:user)
      user2 = create(:user)
      conversation = create(:conversation, author: user1, recipient: user2)

      message1 = MessageCreator.new.create(
        conversation: conversation,
        author: user1,
        body: "Hi"
      )
      message2 = MessageCreator.new.create(
        conversation: conversation,
        author: user2,
        body: "Hi, back"
      )

      expect(message1.recipient).to eq(user2)
      expect(message2.recipient).to eq(user1)
    end

    it "adds a hat to the message" do
      conversation = create(:conversation)
      hat = create(:hat)

      message = MessageCreator.create(
        conversation: conversation,
        author: conversation.author,
        body: "Hi",
        hat_id: hat.id,
      )

      expect(message.hat).to eq(hat)
    end

    it "creates a mod note for the message" do
      expect(ModNote.count).to eq(0)

      conversation = create(:conversation)
      hat = create(:hat, :for_modnotes)

      message = MessageCreator.create(
        conversation: conversation,
        author: conversation.author,
        body: "Hi",
        hat_id: hat.id,
        create_modnote: true,
      )

      expect(ModNote.count).to eq(1)
    end
  end
end
