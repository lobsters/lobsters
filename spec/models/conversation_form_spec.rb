require "rails_helper"

RSpec.describe ConversationForm do
  describe "#create" do
    it "creates a conversation" do
      expect {
        author = create(:user)

        ConversationForm.new(
          author: author,
          username: create(:user).username,
          subject: "this is a subject",
          body: "this is the body",
        ).save
      }.to change { Conversation.count }.by(1)
    end

    it "creates an associated message" do
      username = create(:user).username
      author = create(:user)

      cf = ConversationForm.new(
        author: author,
        username: username,
        subject: "this is a subject",
        body: "this is the body",
      )
      cf.save

      expect(cf.message).to be_persisted
      expect(cf.message.body).to eq("this is the body")
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
