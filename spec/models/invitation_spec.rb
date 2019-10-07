require 'rails_helper'

describe Invitation do
  it "has a limit on the email field" do
    invitation = build(:invitation, email: "a" * 256)
    expect(invitation).to_not be_valid
  end

  it "has a limit on the code field" do
    invitation = build(:invitation)
    invitation.code = "a" * 256
    expect(invitation).to_not be_valid
  end

  it "has a limit on the memo field" do
    invitation = build(:invitation, memo: "a" * 256)
    expect(invitation).to_not be_valid
  end
end
