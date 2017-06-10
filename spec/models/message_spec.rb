require "spec_helper"

describe Message do
  it "should get a short id" do
    m = Message.make!
    expect(m.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end
end
