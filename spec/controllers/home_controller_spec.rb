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
        get :upvoted, as: :rss, session: {u: user.session_token}
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
        get :hidden, session: {u: user.session_token}
        expect(response).to be_successful
      end

      it "does not be redirected" do
        get :hidden, session: {u: user.session_token}
        expect(response).not_to be_redirect
      end

      it "the page has a correct title" do
        get :hidden, session: {u: user.session_token}
        expect(@controller.view_assigns["title"]).to eq("Hidden Stories")
      end

      context "the story is not hidden" do
        it "no stories" do
          get :hidden, session: {u: user.session_token}

          expect(@controller.view_assigns["stories"]).not_to include(story)
        end
      end

      context "the story is hidden" do
        before { HiddenStory.hide_story_for_user(story, user) }

        it "story has been shown" do
          get :hidden, session: {u: user.session_token}

          expect(@controller.view_assigns["stories"]).to include(story)
        end
      end
    end
  end

  describe "#active" do
    let!(:active_story) { create :story, user: }
    let!(:hidden_story) { create :story, user: }

    it "renders successful" do
      get :active, session: {u: user.session_token}

      expect(response).to be_successful
    end

    it "the page has a correct title" do
      get :active, session: {u: user.session_token}

      expect(@controller.view_assigns["title"]).to eq("Active Discussions")
    end

    it "active story has been available" do
      get :active, session: {u: user.session_token}

      expect(@controller.view_assigns["stories"]).to include(active_story)
    end

    it "hidden story has not been available" do
      HiddenStory.hide_story_for_user hidden_story, user

      get :active, session: {u: user.session_token}

      expect(@controller.view_assigns["stories"]).not_to include(hidden_story)
    end
  end

  describe "#index" do
    let!(:active_story) { create :story, user: }
    let!(:hidden_story) { create :story, user: }
    let!(:negative_story) { create :story, user:, score: -1 }

    it "renders successful" do
      get :index, session: {u: user.session_token}

      expect(response).to be_successful
    end

    it "the page has a correct title" do
      get :index, session: {u: user.session_token}

      expect(@controller.view_assigns["title"]).to eq("")
    end

    it "active story has been available" do
      get :index, session: {u: user.session_token}

      expect(@controller.view_assigns["stories"]).to include(active_story)
    end

    it "hidden story has not been available" do
      HiddenStory.hide_story_for_user hidden_story, user

      get :index, session: {u: user.session_token}

      expect(@controller.view_assigns["stories"]).not_to include(hidden_story)
    end

    it "story with negative score has not been available" do
      get :index, session: {u: user.session_token}

      expect(@controller.view_assigns["stories"]).not_to include(negative_story)
    end
  end
end
