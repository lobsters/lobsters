# typed: false

require "rails_helper"

describe Hat do
  it "has a hat field" do
    hat = Hat.new(hat: nil)
    expect(hat).to_not be_valid
  end

  it "has a limit on the hat field" do
    hat = build(:hat, hat: "a" * 256)
    expect(hat).to_not be_valid
  end

  it "has a limit on the link field" do
    hat = build(:hat, link: "a" * 256)
    expect(hat).to_not be_valid
  end

  it "santizes email addresses" do
    hat = build(:hat, link: "foo@bar.com")
    expect(hat.sanitized_link).to eq("bar.com")
  end

  it "doesn't sanitize links that aren't email addressees" do
    hat = build(:hat, link: "google.com")
    expect(hat.sanitized_link).to eq("google.com")
  end
end
