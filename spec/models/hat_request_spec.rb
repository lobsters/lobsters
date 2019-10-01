require 'spec_helper'

describe HatRequest do
  it "has a limit on the hat field" do
    hat_request = HatRequest.make!
    hat_request.hat = "a" * 256
    expect(hat_request).to_not be_valid
  end

  it "has a limit on the link field" do
    hat_request = HatRequest.make!
    hat_request.link = "a" * 256
    expect(hat_request).to_not be_valid
  end

  it "has a limit on the comment field" do
    hat_request = HatRequest.make!
    hat_request.comment = "a" * 65536
    expect(hat_request).to_not be_valid
  end
end
