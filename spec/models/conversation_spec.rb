require "rails_helper"

RSpec.describe Conversation do
  include ActiveSupport::Testing::TimeHelpers

  context "validations" do
    it "should have a valid factory" do
      conversation = build(:conversation)

      expect(conversation).to be_valid
    end

    it "should not allow self-messages" do
      author = build(:user)
      conversation = build(:conversation, author: author, recipient: author)

      expect(conversation).not_to be_valid
    end

    it "should limit the length of conversations" do
      too_long_subject = "a" * 256
      conversation = build(:conversation, subject: too_long_subject)

      expect(conversation).not_to be_valid
    end
  end

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
          updated_at: Time.zone.now,
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
          updated_at: Time.zone.now,
          recipient: user,
        )

        conversations = Conversation.involving(user)

        expect(conversations).to match_array([updated_convo])
      end
    end
  end

  describe ".check_for_both_deleted" do
    it "needs both partners to delete the conversation to be deleted" do
      conversation = create(:conversation)
      travel_to(1.day.ago) do
        MessageForm.new(
          conversation: conversation,
          author: conversation.author,
          body: "hi",
        ).save
      end

      expect(Conversation.count).to eq(1)

      conversation.update(deleted_by_author_at: Time.zone.now)

      expect(Conversation.count).to eq(1)

      conversation.update(deleted_by_recipient_at: Time.zone.now)

      expect(Conversation.count).to eq(0)
    end
  end
end
