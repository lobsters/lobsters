# typed: false

require "rails_helper"

describe "Mod::StoriesController", type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:mod) { create(:user, :moderator) }

  context "mod editing a story" do
    it "edit the title and redirect to story" do
      sign_in mod

      renamed_title_text = "New Title"

      patch "/mod/stories/#{story.short_id}", params: {
        story: {title: renamed_title_text}
      }

      story.reload
      expect(response).to redirect_to(story.comments_path)
      follow_redirect!

      expect(response.body).to include(renamed_title_text)
    end
  end
end
