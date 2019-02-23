require "rails_helper"

RSpec.describe Conversation do
  it "should get a short id" do
    short_id = instance_double(ShortId, generate: "abc123")
    allow(ShortId).to receive(:new).and_return(short_id)
    conversation = create(:conversation)

    expect(conversation.short_id).to match("abc123")
  end
end
