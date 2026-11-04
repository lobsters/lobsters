require "rails_helper"

describe HotspotIndexJob do
  it "adds a comment to the bad set once enough flags arrive" do
    c = create(:comment, comment: "monad")
    expect {
      create_list(:user, 3).each do |u|
        Vote.vote_thusly_on_story_or_comment_for_user_because(-1, c.story_id, c.id, u.id, "T")
      end
    }.to have_enqueued_job(HotspotIndexJob).exactly(3).times # once per flag

    HotspotIndexJob.perform_now(c)
    expect(HotspotDoc.find_by(comment: c).terms).to eq(["monad"])
    expect(HotspotTerm.count).to eq(0) # refreshed, but below MIN_BAD_DOCS
  end
end
