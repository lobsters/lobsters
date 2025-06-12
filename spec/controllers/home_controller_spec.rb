# typed: false

require "rails_helper"

describe HomeController do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:mod) { create(:user, :moderator) }

  describe "#for_domain" do
    it "returns stories for a domain" do
      get :for_domain, params: {id: story.domain.domain}

      expect(response).to be_successful
      expect(@controller.view_assigns["title"]).to include(story.domain.domain)
      expect(@controller.view_assigns["stories"]).to include(story)
    end
  end

  describe "#upvoted" do
    it "redirects to the login page" do
      get :upvoted
      expect(response).to be_redirect
    end

    context "when accessing RSS feeds" do
      it "supports session-based access" do
        stub_login_as user
        get :upvoted, as: :rss
        expect(response).to be_successful
      end

      it "supports token-based access" do
        get :upvoted, as: :rss, params: {token: user.rss_token}
        expect(response).to be_successful
      end
    end
  end

  describe "routing hassle with unsupported formats #746 and #1114" do
    it "404s for /recent.rss, which is not served" do
      get :recent, format: :rss
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "#hidden" do
    context "when user is not authenticated" do
      it "redirects to the login page" do
        get :hidden

        expect(response).to be_redirect
      end
    end

    describe "when user is authenticated" do
      it "renders the hidden page" do
        stub_login_as user
        get :hidden
        expect(response).to be_successful
        expect(response).not_to be_redirect
        expect(@controller.view_assigns["title"]).to eq("Hidden Stories")
      end

      it "doesn't list stories that aren't hidden" do
        stub_login_as user
        get :hidden
        expect(@controller.view_assigns["stories"]).not_to include(story)
      end

      it "lists stories the user has hiddden" do
        stub_login_as user
        HiddenStory.hide_story_for_user(story, user)
        get :hidden
        expect(@controller.view_assigns["stories"]).to include(story)
      end
    end
  end

  describe "#active" do
    it "shows recent, unhidden stories" do
      active_story = create :story
      hidden_story = create :story, user: user
      HiddenStory.hide_story_for_user hidden_story, user
      stub_login_as user

      get :active
      expect(response).to be_successful
      expect(@controller.view_assigns["title"]).to eq("Active Discussions")
      expect(@controller.view_assigns["stories"]).to include(active_story)
      expect(@controller.view_assigns["stories"]).not_to include(hidden_story)
    end
  end

  describe "#index" do
    it "includes stories that are not hidden or having negative score" do
      active_story = create :story
      hidden_story = create :story
      HiddenStory.hide_story_for_user hidden_story, user
      negative_story = create :story, score: -1
      stub_login_as user
      get :index

      expect(response).to be_successful
      expect(@controller.view_assigns["title"]).to eq("")
      expect(@controller.view_assigns["stories"]).to include(active_story)
      expect(@controller.view_assigns["stories"]).not_to include(hidden_story)
      expect(@controller.view_assigns["stories"]).not_to include(negative_story)
    end
  end
end
