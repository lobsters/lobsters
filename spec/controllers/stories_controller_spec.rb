require "rails_helper"

describe StoriesController do
  let(:user) { create(:user) }

  before do
    stub_login_as user
  end

  describe "#delete" do
    let(:story) { create(:story, user: user) }

    it "increments the user's count of deleted stories" do
      expect {
        delete :destroy, params: { id: story.short_id }
      }.to change { user.stories_deleted_count }.by(1)
    end
  end

  describe "#undelete" do
    let(:deleted_story) { create(:story, :deleted, user: user) }

    it "decrements the user's count of deleted stories" do
      expect do
        post :undelete, params: { story_id: deleted_story.short_id }
      end.to change { user.stories_deleted_count }.by(-1)
    end
  end
end
