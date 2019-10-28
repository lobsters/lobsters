require "rails_helper"

describe Message do
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
