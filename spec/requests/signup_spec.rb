# typed: false

require "rails_helper"

describe "signup", type: :request do
  let!(:inactive_user) { create(:user, :inactive) }
  let(:sender) { create(:user) }
  let(:invitation) { create(:invitation, user: sender) }

  describe "tattling on logged-in users who visit invite URLs" do
    before { sign_in sender }

    it "creates a ModNote" do
      expect {
        get "/invitations/#{invitation.code}"
      }.to change { ModNote.count }.by(1)
    end
  end
end
