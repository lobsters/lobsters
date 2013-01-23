require "spec_helper"

describe Message do
  it "should get a short id" do
    m = Message.make!
    m.short_id.should match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end
end
