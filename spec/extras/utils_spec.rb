require "rails_helper"

describe Utils do
  describe ".silence_streams" do
    it "is defined" do
      expect(Utils.methods).to include(:silence_stream)
    end
  end
end
