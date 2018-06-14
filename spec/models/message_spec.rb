require "rails_helper"

describe Message do
  it "should get a short id" do
    m = create(:message)
    expect(m.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  describe "hat" do
    it "can't be worn if user doesn't have that hat" do
      message = build(:message, hat: create(:hat))
      message.valid?
      expect(message.errors[:hat]).to eq(['not wearable by author'])
    end

    it "can be one of the user's hats" do
      user = create(:user)
      hat = create(:hat, user: user)
      message = create(:message, author: user, hat: hat)
      message.valid?
      expect(message.errors[:hat]).to be_empty
    end
  end
end
