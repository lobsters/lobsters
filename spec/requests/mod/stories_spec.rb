# typed: false

require "rails_helper"

describe "Mod::StoriesController", type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:mod) { create(:user, :moderator) }

  before do
    sign_in mod
  end

  context "mod editing a story" do
    it "edit the title and redirect to story" do
      renamed_title_text = "New Title"

      patch "/mod/stories/#{story.short_id}", params: {
        story: {
          title: renamed_title_text
        }
      }

      story.reload
      expect(response).to redirect_to(story.comments_path)
      follow_redirect!

      expect(response.body).to include(renamed_title_text)
    end
  end

  context "mod deleting a story" do
    it "delete a story with moderation reason" do
      patch "/mod/stories/#{story.short_id}/destroy", params: {
        story: {
          moderation_reason: "cuz"
        }
      }

      story.reload
      expect(response).to redirect_to(story.comments_path)
      follow_redirect!

      expect(response.body).to include("Story removed by moderator")
      expect(story.is_deleted).to be_truthy
    end
  end

  context "mod undeleting a story" do
    it "undelete a story" do
      deleted_story = create(:story, :deleted, user: user)

      patch "/mod/stories/#{deleted_story.short_id}/undelete", params: {
        story: {
          title: deleted_story.title
        }
      }

      deleted_story.reload
      expect(response).to redirect_to(deleted_story.comments_path)
      expect(deleted_story.is_deleted).to be_falsey
    end
  end
end
