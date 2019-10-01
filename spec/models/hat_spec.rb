require 'spec_helper'

describe Hat do
  it "has a hat field" do
    hat = Hat.new(hat: nil)
    expect(hat).to_not be_valid
  end

  it "has a limit on the hat field" do
    hat = Hat.make!
    hat.hat = "a" * 256
    expect(hat).to_not be_valid
  end

  it "has a limit on the link field" do
    hat = Hat.make!
    hat.link = "a" * 256
    expect(hat).to_not be_valid
  end
end
