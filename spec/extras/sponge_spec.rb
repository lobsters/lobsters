# typed: false

require "rails_helper"

describe Sponge do
  describe "#try_fetch" do
    it "ignores other people's problems" do
      expect(Sponge.new.try_fetch("http://localhost/status")).to be_nil
    end

    it "raises errors that are internal to Sponge" do
      s = Sponge.new
      allow(s).to receive(:fetch).and_raise(NoMethodError)
      expect { s.try_fetch("https://example.com/") }.to raise_error(NoMethodError)
    end
  end
end
