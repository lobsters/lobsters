require "rails_helper"

RSpec.describe Username, type: :model do
  it "can rename! users" do
    user = create :user, username: "alice"

    Username.rename! user:, from: "alice", to: "bob", by: user
    moderation = Moderation.last
    expect(moderation.action).to include("own username")

    u1 = user.usernames.first
    expect(u1.username).to eq("alice")
    expect(u1.renamed_away_at).to_not eq(nil)

    u2 = user.usernames.last
    expect(u2.username).to eq("bob")
    expect(u2.renamed_away_at).to eq(nil)
  end
end
