require "rails_helper"

describe HomeController do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }
  let(:mod) { create(:user, :moderator) }

  describe "#for_domain" do
    it 'returns stories for a domain' do
      get :for_domain, params: { domain: story.domain.domain }

      expect(response).to be_successful
      expect(@controller.view_assigns['title']).to include(story.domain.domain)
      expect(@controller.view_assigns['stories']).to include(story)
    end
  end
end
