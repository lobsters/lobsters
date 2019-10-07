require 'rails_helper'

describe InvitationRequest do
  it "has a limit on the email field" do
    invitation_request = build(:invitation_request, email: "a" * 256)
    expect(invitation_request).to_not be_valid
  end

  it "has a limit on the code field" do
    invitation_request = build(:invitation_request)
    invitation_request.code = "a" * 256
    expect(invitation_request).to_not be_valid
  end

  it "has a limit on the memo field" do
    invitation_request = build(:invitation_request, memo: "a" * 256)
    expect(invitation_request).to_not be_valid
  end

  it "has a limit on the name field" do
    invitation_request = build(:invitation_request, name: "a" * 256)
    expect(invitation_request).to_not be_valid
  end

  it "has a limit on the ip_address field" do
    invitation_request = build(:invitation_request, ip_address: "a" * 256)
    expect(invitation_request).to_not be_valid
  end
end
