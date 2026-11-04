require "rails_helper"

describe "Mod::HotspotsController", type: :request do
  before { sign_in create(:user, :moderator) }

  def hotspot_doc(comment, logit)
    HotspotDoc.create!(comment: comment,
      terms: ["monad"],
      token_count: 1,
      bad: false,
      logit: logit,
      matched_terms: {"monad" => logit})
  end

  it "shows matched comments, including author-deleted ones" do
    shown = create(:comment, comment: "monad shown", is_deleted: true)
    hidden = create(:comment, comment: "monad moderated", is_deleted: true, is_moderated: true)
    hotspot_doc(shown, 1.0)
    create(:vote, comment: shown, story: shown.story, vote: -1, reason: "T")
    shown.update_column(:flags, 1)
    hotspot_doc(hidden, 1.0)

    get "/mod/hotspots/1d"
    expect(response.body).to include("monad shown")
    expect(response.body).to include("Comment removed by its author")
    expect(response.body).to include("1 troll (")
    expect(response.body).to include("comment_hotspot")
    expect(response.body).to include("/search?order=newest&amp;q=monad&amp;what=comments")
    expect(response.body).not_to include("monad moderated")
  end
end
