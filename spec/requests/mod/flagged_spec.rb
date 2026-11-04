require "rails_helper"

describe "Mod::FlaggedController", type: :request do
  let(:mod) { create(:user, :moderator) }

  before { sign_in mod }

  it "shows comments with 3 flags" do
    comment = create(:comment, comment: "flagged comment body")
    3.times do
      create(:vote, comment: comment, story: comment.story, vote: -1, reason: "T")
    end
    comment.update_column(:flags, 3)

    get "/mod/flagged_comments/1d"
    expect(response.status).to eq(200)
    expect(response.body).to include("flagged comment body")
    expect(response.body).to include("3 troll (")
    expect(Comment.mod_flagged).to include(comment)
  end
end
