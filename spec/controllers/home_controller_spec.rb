require "rails_helper"

describe HomeController do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:mod) { create(:user, :moderator) }

  describe "#for_domain" do
    it 'returns stories for a domain' do
      get :for_domain, params: { name: story.domain.domain }

      expect(response).to be_successful
      expect(@controller.view_assigns['title']).to include(story.domain.domain)
      expect(@controller.view_assigns['stories']).to include(story)
    end
  end

  describe "#upvoted" do
    it "redirects to the login page" do
      get :upvoted
      expect(response).to be_redirect
    end

    context "when accessing RSS feeds" do
      it "supports session-based access" do
        get :upvoted, as: :rss, session: { u: user.session_token }
        expect(response).to be_successful
      end

      it "supports token-based access" do
        get :upvoted, as: :rss, params: { token: user.rss_token }
        expect(response).to be_successful
      end
    end
  end
end
