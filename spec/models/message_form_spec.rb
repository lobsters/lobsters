require "rails_helper"

RSpec.describe MessageForm do
  describe "#create" do
    it "creates a message on a conversation" do
      expect(Message.count).to eq(0)

      conversation = create(:conversation)

      form = MessageForm.new(
        conversation: conversation,
        author: conversation.author,
        body: "Hi"
      ).tap(&:save)
      conversation.reload

      expect(Message.count).to eq(1)
      expect(conversation.messages.last).to eq(form.message)
    end

    it "uses the conversation subject" do
      conversation = create(:conversation, subject: "Here I am")

      form = MessageForm.new(
        conversation: conversation,
        author: conversation.author,
        body: "Hi"
      ).tap(&:save)

      expect(form.message.subject).to eq("Here I am")
    end

    it "sets the recipient to the other person in the conversation" do
      user1 = create(:user)
      user2 = create(:user)
      conversation = create(:conversation, author: user1, recipient: user2)

      form1 = MessageForm.new(
        conversation: conversation,
        author: user1,
        body: "Hi"
      ).tap(&:save)
      form2 = MessageForm.new(
        conversation: conversation,
        author: user2,
        body: "Hi, back"
      ).tap(&:save)

      expect(form1.message.recipient).to eq(user2)
      expect(form2.message.recipient).to eq(user1)
    end

    it "adds a hat to the message" do
      conversation = create(:conversation)
      hat = create(:hat)

      form = MessageForm.new(
        conversation: conversation,
        author: conversation.author,
        body: "Hi",
        hat_id: hat.id,
      ).tap(&:save)

      expect(form.message.hat).to eq(hat)
    end

    it "creates a mod note for the message" do
      expect(ModNote.count).to eq(0)

      author = create(:user, is_moderator: true)
      conversation = create(:conversation, author: author)
      hat = create(:hat, :for_modnotes)

      conversation.author.update(is_moderator: true)

      MessageForm.new(
        conversation: conversation,
        author: author,
        body: "Hi",
        hat_id: hat.id,
        mod_note: "1",
      ).save

      expect(ModNote.count).to eq(1)
    end

    context "when the user is not a moderator" do
      it "does not create a modnote" do
        expect(ModNote.count).to eq(0)

        author = create(:user, is_moderator: true)
        conversation = create(:conversation, author: author)
        hat = create(:hat, :for_modnotes)

        MessageForm.new(
          conversation: conversation,
          author: author,
          body: "Hi",
          hat_id: hat.id,
          mod_note: "1",
        ).save

        expect(ModNote.count).to eq(1)
      end
    end
  end
end
