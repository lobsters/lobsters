require "rails_helper"

describe Message do
  it "should get a short id" do
    m = Message.make!
    expect(m.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end
  describe "hat_id" do
    it "must be wearable by author" do
      expect {
        Message.make!(hat: Hat.make!)
      }.to raise_error(ActiveRecord::RecordInvalid, /hat/i)

      user = User.make!
      hat = Hat.make!(user_id: user.id)
      expect {
        Message.make!(author_user_id: user.id, hat: hat)
      }.to_not raise_error
    end
  end
end
