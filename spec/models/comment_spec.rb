require "spec_helper"

describe Comment do
  it "should get a short id" do
    c = Comment.make!(:comment => "hello")

    expect(c.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end
end
