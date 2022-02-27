require 'rails_helper'

describe 'stores', type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:mod) { create(:user, :moderator) }

  describe "#check_url_dupe" do
    before { sign_in user }

    context "json" do
      let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

      it "returns similar story matching URL" do
        post "/stories/check_url_dupe",
             params: { story: { title: "some other title", url: story.url } }.to_json,
             headers: headers

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
        post "/stories/check_url_dupe",
             params: { story: { title: "some other title", url: story.url[0...-1] } }.to_json,
             headers: headers

        expect(response).to be_successful

        json = JSON.parse(response.body)

        expect(json.fetch("title")).to eq "some other title"
        expect(json.fetch("similar_stories").count).to eq(0)
      end

      it "returns no matches if no matching URL" do
        post "/stories/check_url_dupe",
             params: { story: { title: "some other title", url: "invalid_url" } }.to_json,
             headers: headers

        expect(response).to be_successful

        json = JSON.parse(response.body)

        expect(json.fetch("title")).to eq "some other title"
        expect(json.fetch("similar_stories").count).to eq(0)
      end

      it "throws a 400 if there's no URL present" do
        expect {
          post "/stories/check_url_dupe",
               params: { story: { url: "" } }.to_json,
               headers: headers
        }.to raise_error(ActionController::ParameterMissing)

        expect {
          post "/stories/check_url_dupe",
               params: { story: {} }.to_json,
               headers: headers
        }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe "#delete" do
    before { sign_in user }

    it "increments the user's count of deleted stories" do
      expect {
        put "/stories/#{story.short_id}/destroy", params: {
          id: story.short_id,
          story:  {
            title: story.title,
          },
        }
      }.to change { user.stories_deleted_count }.by(1)
    end
  end

  describe "#undelete" do
    before { sign_in user }

    let(:deleted_story) { create(:story, :deleted, user: user) }

    it "decrements the user's count of deleted stories" do
      expect {
        put "/stories/#{deleted_story.short_id}/undelete", params: {
          id: deleted_story.short_id,
          story:  {
            title: deleted_story.title,
          },
        }
      }.to change { user.stories_deleted_count }.by(-1)
    end
  end

  describe "merged stories" do
    it "can be merged by mod" do
      sign_in mod
      s = create(:story)
      put "/stories/#{s.short_id}",
          params: {
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
      sign_in user

      s = create(:story)
      put "/stories/#{s.short_id}",
          params: {
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
    it "displays a story" do
      story = create(:story)
      get story_path(story)

      expect(response).to be_successful
      expect(response.body).to include(story.title)
    end

    context "story removed by submitter" do
      let(:story) { create(:story, is_deleted: false) }

      # feels brittle to copy StoriesController and keep leaning on the
      # log_moderation callback but too big a refactor right now
      before do
        story.is_deleted = true
        story.editor = story.user
        story.save!
      end

      it "404s to logged-out visitor" do
        get story_path(story)

        expect(response.status).to eq(404)
        expect(response.body).to_not include(story.title)
        expect(response.body).to_not include('removed by moderator')
        expect(response.body).to_not include('removed by submitter')
        expect(response.body).to_not include(story.user.username)
      end

      it "shows submitter removed to logged-in user" do
        sign_in create(:user)
        get story_path(story)

        expect(response.status).to eq(404)
        expect(response.body).to_not include(story.title)
        expect(response.body).to include('removed by submitter')
        expect(response.body).to include(story.user.username)
      end
    end

    context "story removed by moderator" do
      let(:story) { create(:story, is_deleted: false) }
      let(:mod) { create(:user, :moderator) }
      let(:reason) { "Unacceptably low ratio of cat photos to words." }

      # feels brittle to copy StoriesController and keep leaning on the
      # log_moderation callback but too big a refactor right now
      before do
        story.moderation_reason = reason
        story.is_deleted = true
        story.editor = mod
        story.save!
      end

      it "404s to logged-out visitor" do
        get story_path(story)

        expect(response.status).to eq(404)
        expect(response.body).to_not include(story.title)
        expect(response.body).to_not include(reason)
        expect(response.body).to_not include('removed by submitter')
        expect(response.body).to_not include(story.user.username)
      end

      it "shows mod log to logged-in user" do
        sign_in create(:user)
        get story_path(story)

        expect(response.status).to eq(404)
        expect(response.body).to_not include(story.title)
        expect(response.body).to include(reason)
      end
    end

    context "json" do
      let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }

      context "for a story that merged into another story" do
        let(:merged_into_story) { create(:story) }
        let(:story) { create(:story, merged_into_story: merged_into_story) }

        it "redirects to the merged story's json" do
          get "/stories/#{story.short_id}",
              headers: headers
          expect(response).to redirect_to(action: :show,
                                          id: merged_into_story.short_id,
                                          format: :json)
        end
      end
    end
  end

  describe "upvoting" do
    let(:target) { create(:story) }

    before { sign_in user }

    it 'works' do
      expect {
        post "/stories/#{target.short_id}/upvote"
        expect(response.status).to eq(200)
      }.to change { target.reload.score }.by(1)
      expect(Vote.where(user: user).count).to eq(1)
    end

    it 'does nothing to deleted comments' do
      expect {
        target.is_deleted = true
        target.editor = target.user
        target.save!

        post "/stories/#{target.short_id}/upvote"
        expect(response.status).to eq(400)
      }.to change { target.reload.score }.by(0)
      expect(Vote.where(user: user).count).to eq(0)
    end
  end
end
