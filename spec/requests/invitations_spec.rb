# typed: false

require "rails_helper"

describe "invitations", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /invitations" do
    it "creates and emails an invitation" do
      expect {
        post "/invitations", params: {email: "new@example.com", memo: "hi"}
      }.to change { Invitation.count }.by(1)
        .and change { ActionMailer::Base.deliveries.size }.by(1)
      expect(flash[:success]).to match(/Successfully/)
    end

    it "doesn't save the invitation if the email can't be sent" do
      allow(InvitationMailer).to receive(:invitation).and_raise(Errno::ECONNREFUSED)
      expect {
        post "/invitations", params: {email: "new@example.com", memo: "hi"}
      }.not_to change { Invitation.count }
      expect(flash[:error]).to be_present
    end
  end
end
