require 'rails_helper'

describe 'merged stories', type: :request do
  let(:user) { create(:user) }
  let(:mod) { create(:user, :moderator) }
  let(:merged_story) { create(:story) }
  let(:story) { create(:story) }

  context 'user votes on merged story' do
    before do
      sign_in mod
      put "/stories/#{merged_story.short_id}", params: {
        story: {
          merge_story_short_id: story.short_id,
          moderation_reason: 'cuz',
        },
      }
      sign_in user
    end

    it "does nothing when upvoting merged story" do
      post "/stories/#{merged_story.short_id}/upvote"

      merged_story.reload
      expect(merged_story.merged_into_story).to eq story
      expect(merged_story.upvotes).to eq(1)
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
