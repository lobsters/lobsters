# typed: false

require "rails_helper"

describe Moderation do
  let(:value) { "a" * 16_777_216 }

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

  it "validates a moderation linked to exactly one object" do
    user = create :user
    comment = create :comment, user: user
    domain = create :domain
    story = create :story, user: user
    tag = create :tag
    action = "edited"

    valid_moderations = [
      Moderation.new(comment:, action:),
      Moderation.new(domain:, action:),
      Moderation.new(story:, action:),
      Moderation.new(tag:, action:),
      Moderation.new(user:, action:)
    ]
    expect(valid_moderations).to all(be_valid)

    invalid_moderations = [
      Moderation.new,
      Moderation.new(comment:, domain:, action:),
      Moderation.new(comment:, domain:, story:, action:),
      Moderation.new(comment:, domain:, story:, tag:, action:),
      Moderation.new(comment:, domain:, story:, tag:, user:, action:)
    ]
    invalid_moderations.each do |moderation|
      expect(moderation).not_to be_valid
      expect(moderation.errors.messages.dig(:base))
        .to eq(["moderation should be linked to only one object"])
    end
  end
end
