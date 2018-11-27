require "rails_helper"

describe StoriesController do
  let(:user) { create(:user) }

  before do
    stub_login_as user
  end

  describe "#check_url_dupe" do
    let(:story) { create(:story, user: user) }

    context "json" do
      it "returns similar story matching URL" do
        post :check_url_dupe,
             format: :json,
             params: { story: { title: "some other title", url: story.url } }

        expect(response).to be_successful

        json = JSON.parse(response.body)

        expect(json.fetch("title")).to eq "some other title"
        expect(json.fetch("similar_stories").count).to eq(1)

        similar_story = json.fetch("similar_stories").first
        expect(similar_story.fetch("title")).to eq story.title
        expect(similar_story.fetch("short_id")).to eq story.short_id
        expect(similar_story.fetch("url")).to eq story.url
        expect(similar_story.fetch("comments_url")).to eq story.comments_url
        expect(similar_story.fetch("comment_count")).to eq story.comments_count
      end

      it "returns no matches if previously submitted URL is only partial match" do
        post :check_url_dupe,
             format: :json,
             params: { story: { title: "some other title", url: story.url[0...-1] } }

        expect(response).to be_successful

        json = JSON.parse(response.body)

        expect(json.fetch("title")).to eq "some other title"
        expect(json.fetch("similar_stories").count).to eq(0)
      end

      it "returns no matches if no matching URL" do
        post :check_url_dupe,
             format: :json,
             params: { story: { title: "some other title", url: "invalid_url" } }

        expect(response).to be_successful

        json = JSON.parse(response.body)

        expect(json.fetch("title")).to eq "some other title"
        expect(json.fetch("similar_stories").count).to eq(0)
      end
    end
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
