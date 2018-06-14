require "rails_helper"

describe Comment do
  it "should get a short id" do
    c = Comment.make!(:comment => "hello")

    expect(c.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  describe "hat" do
    it "can't be worn if user doesn't have that hat" do
      comment = Comment.make(hat: Hat.make!)
      comment.valid?
      expect(comment.errors[:hat]).to eq(['not wearable by user'])
    end

    it "can be one of the user's hats" do
      user = User.make!
      hat = Hat.make!(user_id: user.id)
      comment = Comment.make!(user_id: user.id, hat: hat)
      comment.valid?
      expect(comment.errors[:hat]).to be_empty
    end
  end
end
