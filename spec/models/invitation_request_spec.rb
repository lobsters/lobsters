require 'rails_helper'

describe InvitationRequest do
  it "has a valid factory" do
    invitation_request = build(:invitation_request)
    expect(invitation_request).to be_valid
  end

  it "has a limit on the email field" do
    invitation_request = build(:invitation_request, email: "a" * 256 + '@b.b')
    invitation_request.valid?
    expect(invitation_request.errors[:email]).to eq(['is too long (maximum is 255 characters)'])
  end

  it "creates a code before validation" do
    invitation_request = build(:invitation_request)
    invitation_request.code = 'my code'
    invitation_request.valid?
    expect(invitation_request.code).to_not eq('my_code')
  end

  it "has a limit on the memo field" do
    invitation_request = build(:invitation_request, memo: 'https://' + 'a' * 256)
    invitation_request.valid?
    expect(invitation_request.errors[:memo]).to eq(['is too long (maximum is 255 characters)'])
  end

  it "has a limit on the name field" do
    invitation_request = build(:invitation_request, name: "a" * 256)
    invitation_request.valid?
    expect(invitation_request.errors[:name]).to eq(['is too long (maximum is 255 characters)'])
  end

  it "has a limit on the ip_address field" do
    invitation_request = build(:invitation_request, ip_address: "a" * 256)
    invitation_request.valid?
    expect(invitation_request.errors[:ip_address])
      .to eq(['is too long (maximum is 255 characters)'])
  end
end
