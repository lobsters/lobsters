require "rails_helper"

describe Moderation do
  let(:value) { 'a' * 16_777_216 }

  it "validates the length of action" do
    moderation = Moderation.new(action: value, reason: nil)
    expect(moderation).not_to be_valid
    expect(moderation.errors.messages.dig(:action))
      .to eq(["is too long (maximum is 16777215 characters)"])
  end

  it "validates the length of reason" do
    moderation = Moderation.new(action: nil, reason: value)
    expect(moderation).not_to be_valid
    expect(moderation.errors.messages.dig(:reason))
      .to eq(["is too long (maximum is 16777215 characters)"])
  end
end
