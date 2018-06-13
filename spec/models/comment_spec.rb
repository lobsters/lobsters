require "rails_helper"

describe Comment do
  it "should get a short id" do
    c = create(:comment)

    expect(c.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  describe "hat" do
    it "can't be worn if user doesn't have that hat" do
      comment = build(:comment, hat: build(:hat))
      comment.valid?
      expect(comment.errors[:hat]).to eq(['not wearable by user'])
    end

    it "can be one of the user's hats" do
      hat = create(:hat)
      user = hat.user
      comment = create(:comment, user: user, hat: hat)
      comment.valid?
      expect(comment.errors[:hat]).to be_empty
    end
  end
end
