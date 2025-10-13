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
      }.to change { ModNote.count }.by(2) # one on inviter, one on invitee (though redundnant here)
    end
  end

  it "records a Username" do
    post "/signup", params: {invitation_code: invitation.code, user: {username: "new_user", email: "new_user@example.com", password: "example", password_confirmation: "example"}}

    username = Username.last
    expect(username.username).to eq("new_user")
    expect(username.created_at).to eq(username.user.created_at)
    expect(username.renamed_away_at).to be_nil
  end
end
