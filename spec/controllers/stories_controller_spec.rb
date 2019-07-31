require "rails_helper"

describe StoriesController do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:mod) { create(:user, :moderator) }

  describe "#check_url_dupe" do
    before { stub_login_as user }

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

      it "throws a 400 if there's no URL present" do
        expect {
          post :check_url_dupe,
               format: :json,
               params: { story: { url: "" } }
        }.to raise_error(ActionController::ParameterMissing)

        expect {
          post :check_url_dupe,
               format: :json,
               params: { story: {} }
        }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe "#delete" do
    before { stub_login_as user }

    it "increments the user's count of deleted stories" do
      expect {
        delete :destroy, params: { id: story.short_id }
      }.to change { user.stories_deleted_count }.by(1)
    end
  end

  describe "#undelete" do
    before { stub_login_as user }

    let(:deleted_story) { create(:story, :deleted, user: user) }

    it "decrements the user's count of deleted stories" do
      expect do
        post :undelete, params: { story_id: deleted_story.short_id }
      end.to change { user.stories_deleted_count }.by(-1)
    end
  end

  describe "merged stories" do
    it "can be merged by mod" do
      stub_login_as mod
      s = create(:story)
      post :update, params: {
        id: s.short_id,
        story: {
          merge_story_short_id: story.short_id,
          moderation_reason: 'cuz',
        },
      }
      expect(response).to be_redirect

      s.reload
      expect(s.merged_into_story).to eq(story)

      ml = Moderation.last
      expect(ml.story).to eq(s)
      expect(ml.reason).to eq('cuz')
    end

    it "can't be done by submitter" do
      stub_login_as user

      s = create(:story)
      post :update, params: {
        id: s.short_id,
        story: {
          merge_story_short_id: story.short_id,
          moderation_reason: 'anarchy!',
        },
      }
      expect(response).to be_redirect
      s.reload
      expect(s.merged_into_story).to be_nil
    end
  end

  describe "show" do
    context "json" do
      context "for a story that merged into another story" do
        let(:merged_into_story) { create(:story) }
        let(:story) { create(:story, merged_into_story: merged_into_story) }

        it "redirects to the merged story's json" do
          get :show, params: { id: story.short_id, format: :json }
          expect(response).to redirect_to(action: :show,
                                          id: merged_into_story.short_id,
                                          format: :json)
        end
      end
    end
  end
end
