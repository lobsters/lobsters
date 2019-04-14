require "rails_helper"

RSpec.describe Conversation do
  it "should get a short id" do
    short_id = instance_double(ShortId, generate: "abc123")
    allow(ShortId).to receive(:new).and_return(short_id)
    conversation = create(:conversation)

    expect(conversation.short_id).to match("abc123")
  end

  describe ".involving" do
    context "when the user is the author of the conversation" do
      it "returns conversations that have not been deleted by the author" do
        user = create(:user)
        create(:conversation, :deleted_by_author, author: user)
        recipient_deleted = create(
          :conversation,
          :deleted_by_recipient,
          author: user
        )
        normal = create(:conversation, author: user)

        conversations = Conversation.involving(user)

        expect(conversations).to match_array([recipient_deleted, normal])
      end

      it "returns conversations updated after author deletion" do
        user = create(:user)
        create(:conversation, :deleted_by_recipient, recipient: user)
        updated_convo = create(
          :conversation,
          deleted_by_author_at: 1.minute.ago,
          updated_at: Time.now,
          author: user,
        )

        conversations = Conversation.involving(user)

        expect(conversations).to match_array([updated_convo])
      end
    end

    context "when the user is the recipient of the conversation" do
      it "returns conversations that have not been deleted by the recipient" do
        user = create(:user)
        create(:conversation, :deleted_by_recipient, recipient: user)
        author_deleted = create(
          :conversation,
          :deleted_by_author,
          recipient: user
        )
        normal = create(:conversation, recipient: user)

        conversations = Conversation.involving(user)

        expect(conversations).to match_array([author_deleted, normal])
      end

      it "returns conversations updated after recipient deletion" do
        user = create(:user)
        create(:conversation, :deleted_by_recipient, recipient: user)
        updated_convo = create(
          :conversation,
          deleted_by_recipient_at: 1.minute.ago,
          updated_at: Time.now,
          recipient: user,
        )

        conversations = Conversation.involving(user)

        expect(conversations).to match_array([updated_convo])
      end
    end
  end
end
