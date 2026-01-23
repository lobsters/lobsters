# typed: false

require "rails_helper"

describe Github do
  describe ".enabled?" do
    it "should not be enabled" do
      expect(described_class).not_to be_enabled
    end
  end

  # Github.token_and_user_from_code uses CGI.parse, and this is an easy way to test it is loaded
  describe "CGI.parse" do
    it "should work" do
      expect(CGI.parse("a"))
    end
  end
end
