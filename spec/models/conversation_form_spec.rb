require "rails_helper"

RSpec.describe ConversationForm do
  describe "#create" do
    it "creates a conversation" do
      expect(Conversation.count).to eq(0)
      author = create(:user)

      ConversationForm.new(
        author: author,
        username: create(:user).username,
        subject: "this is a subject",
        body: "this is the body",
      ).save

      expect(Conversation.count).to eq(1)
    end

    it "uses the MessageForm to create an associated message" do
      message = build(:message)
      allow(MessageForm).to receive(:new).and_return(message)
      username = create(:user).username
      author = create(:user)

      ConversationForm.new(
        author: author,
        username: username,
        subject: "this is a subject",
        body: "this is the body",
      ).save

      expect(MessageForm).to have_received(:new)
    end

    it "doesn't allow invalid recipients" do
      expect(Conversation.count).to eq(0)

      author = create(:user)
      ConversationForm.new(
        author: author,
        username: "this_user_doesnt_exist",
        subject: "this is a subject",
        body: "this is the body",
      ).save

      expect(Conversation.count).to eq(0)
    end
  end
end
