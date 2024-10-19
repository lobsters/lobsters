# typed: false

require "rails_helper"

describe Message do
  it "should get a short id" do
    m = create(:message)
    expect(m.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  it "validates the length of short_id" do
    m_valid_short_id = create(:message)
    m_valid_short_id.short_id = "a" * 50
    expect(m_valid_short_id).not_to be_valid
  end

  describe "hat" do
    it "can't be worn if user doesn't have that hat" do
      message = build(:message, hat: create(:hat))
      message.valid?
      expect(message.errors[:hat]).to eq(["not wearable by author"])
    end

    it "can be one of the user's hats" do
      user = create(:user)
      hat = create(:hat, user: user)
      message = create(:message, author: user, hat: hat)
      message.valid?
      expect(message.errors[:hat]).to be_empty
    end
  end

  describe "update_unread_counts" do
    let(:user) { create(:user) }
    let(:message) { create(:message, recipient: user) }

    it "updates the unread message count" do
      message.update_unread_counts
      expect(user.reload.unread_message_count).to eq(1)

      message.destroy!
      expect(user.reload.unread_message_count).to eq(0)
    end
  end
end
