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

    valid_moderations = [Moderation.new(comment: comment),
      Moderation.new(domain: domain),
      Moderation.new(story: story),
      Moderation.new(tag: tag),
      Moderation.new(user: user)]
    expect(valid_moderations).to all(be_valid)

    invalid_moderations = [Moderation.new,
      Moderation.new(comment: comment, domain: domain),
      Moderation.new(comment: comment, domain: domain, story: story),
      Moderation.new(comment: comment, domain: domain, story: story, tag: tag),
      Moderation.new(comment: comment, domain: domain, story: story, tag: tag,
        user: user)]
    invalid_moderations.each do |moderation|
      expect(moderation).not_to be_valid
      expect(moderation.errors.messages.dig(:base))
        .to eq(["moderation should be linked to only one object"])
    end
  end
end
