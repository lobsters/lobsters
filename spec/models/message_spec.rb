require "rails_helper"

describe Message do
  it "should get a short id" do
    m = Message.make!
    expect(m.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  describe "hat" do
    it "can't be worn if user doesn't have that hat" do
      message = Message.make(hat: Hat.make!)
      message.valid?
      expect(message.errors[:hat]).to eq(['not wearable by author'])
    end

    it "can be one of the user's hats" do
      user = User.make!
      hat = Hat.make!(user_id: user.id)
      message = Message.make!(author_user_id: user.id, hat: hat)
      message.valid?
      expect(message.errors[:hat]).to be_empty
    end
  end
end
