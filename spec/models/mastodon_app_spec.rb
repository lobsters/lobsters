# typed: false

require "rails_helper"

RSpec.describe MastodonApp, type: :model do
  describe "#sanitized_instance_name" do
    it "accepts an instance name" do
      expect(MastodonApp.sanitized_instance_name("example.com")).to eq("example.com")
    end

    it "accepts urls" do
      expect(MastodonApp.sanitized_instance_name("https://example.com")).to eq("example.com")
      expect(MastodonApp.sanitized_instance_name("https://example.com/")).to eq("example.com")
      expect(MastodonApp.sanitized_instance_name("https://example.com/@user")).to eq("example.com")
    end

    it "accepts a user id" do
      expect(MastodonApp.sanitized_instance_name("user@example.com")).to eq("example.com")
      expect(MastodonApp.sanitized_instance_name("@user@example.com")).to eq("example.com")
    end
  end
end
