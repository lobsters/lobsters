# typed: false

require "rails_helper"

describe "merged stories", type: :request do
  let(:user) { create(:user) }
  let(:mod) { create(:user, :moderator) }
  let(:story) { create(:story) }
  let(:merged_story) { create(:story, merged_story_id: story.id) }

  context "user votes on merged story" do
    before { sign_in user }

    it "does nothing when upvoting merged story" do
      post "/stories/#{merged_story.short_id}/upvote"

      merged_story.reload
      expect(merged_story.merged_into_story).to eq story
      expect(merged_story.score).to eq(1)
    end

    it "has no effect when hiding merged story" do
      post "/stories/#{merged_story.short_id}/hide"

      merged_story.reload
      expect(merged_story.hider_count).to eq(0)
    end

    it "has no effect when saving merged story" do
      post "/stories/#{merged_story.short_id}/save"

      merged_story.reload
      expect(merged_story.savings.count).to eq(0)
    end
  end
end
