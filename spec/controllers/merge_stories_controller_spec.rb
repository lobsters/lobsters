require 'rails_helper'

RSpec.describe StoriesController, type: :controller do
  let(:user) { create(:user) }
  let(:mod) { create(:user, :moderator) }
  let(:merged_story) { create(:story) }
  let(:story) { create(:story) }

  describe 'merged stories do' do
    context 'user votes on merged story' do
      before {
        stub_login_as user
        stub_login_as mod
        post :update, params: {
          id: merged_story.short_id,
          story: {
            merge_story_short_id: story.short_id,
            moderation_reason: 'cuz',
          },
        }
      }

      it "does nothing when upvoting merged story" do
        post :upvote, params: { story_id: merged_story.short_id }

        merged_story.reload
        expect(merged_story.merged_into_story).to eq story
        expect(merged_story.upvotes).to eq(1)
      end

      it "has no effect when hiding merged story" do
        post :hide, params: { story_id: merged_story.short_id }

        merged_story.reload
        expect(merged_story.hider_count).to eq(0)
      end

      it "has no effect when saving merged story" do
        post :save, params: { story_id: merged_story.short_id }

        merged_story.reload
        expect(merged_story.savings.count).to eq(0)
      end
    end
  end
end
