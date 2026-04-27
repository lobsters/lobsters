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

    it "renders merged stories in recent with disabled upvote control" do
      create_list(:story, StoriesPaginator::STORIES_PER_PAGE + 1, score: 50)

      merged_parent = create(:story, score: 60)
      merged_story = create(
        :story,
        merged_into_story: merged_parent,
        score: 1,
        created_at: 1.day.ago,
        updated_at: 1.day.ago
      )

      get "/recent"

      expect(response).to be_successful

      doc = Nokogiri::HTML.parse(response.body)
      merged_row = doc.at_css("li#story_#{merged_story.short_id}")
      expect(merged_row).to be_present
      expect(merged_row.at_css(".merge")&.text).to include("merged")
      expect(merged_row.at_css(".voters a.upvoter")).to be_nil
      expect(merged_row.at_css(".voters .upvoter.disabled[aria-disabled='true']")).to be_present
    end
  end
end
