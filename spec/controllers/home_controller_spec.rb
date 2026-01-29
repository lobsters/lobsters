# typed: false

require "rails_helper"

describe HomeController do
  let(:user) { create(:user) }
  let!(:story) { create(:story, user: user) }
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

    context "when linking to RSS feeds" do
      it "returns a link that routes to the RSS feed" do
        stub_login_as user
        get :upvoted
        expect(get: @controller.view_assigns["rss_link"][:href]).to route_to(
          controller: "home",
          action: "upvoted",
          format: "rss",
          token: user.rss_token
        )
      end
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

  describe "#newest_by_user" do
    it "includes stories" do
      by_user = create :user, username: "by_user"

      story = create :story, user: by_user, title: "By user story"

      stub_login_as user
      get :newest_by_user, params: {user: by_user}

      expect(response).to be_successful
      expect(@controller.view_assigns["title"]).to eq("Newest Stories by #{by_user.username}")
      expect(@controller.view_assigns["stories"].map(&:title)).to include(story.title)
    end
  end

  describe "#saved" do
    it "includes only saved stories by user" do
      saved_story = create(:story)
      other_story = create(:story)

      SavedStory.create!(user: user, story: saved_story)

      stub_login_as user
      get :saved

      expect(response).to be_successful
      expect(@controller.view_assigns["title"]).to eq("Saved Stories")
      expect(@controller.view_assigns["stories"]).to include(saved_story)
      expect(@controller.view_assigns["stories"]).not_to include(other_story)
    end
  end

  describe "#single_tag" do
    it "includes only story with the tag" do
      tag = create :tag
      tagged_story = create(:story, tags: [tag])
      other_story = create :story

      stub_login_as user
      get :single_tag, params: {tag: tag.tag}

      expect(response).to be_successful
      expect(@controller.view_assigns["title"]).to eq([tag.tag, tag.description].join(" - "))
      expect(@controller.view_assigns["stories"]).to include(tagged_story)
      expect(@controller.view_assigns["stories"]).not_to include(other_story)
    end
  end

  describe "#multi_tag" do
    it "includes only stories with the given tags" do
      tag1 = create :tag
      tag2 = create :tag

      story1 = create :story, tags: [tag1]
      story2 = create :story, tags: [tag2]
      story3 = create :story, tags: [tag1, tag2]
      story4 = create :story

      stub_login_as user
      get :multi_tag, params: {tag: [tag1, tag2].map(&:tag).join(",")}

      title = [tag1, tag2].map { [it.tag, it.description].join(" - ") }.join(" ")

      expect(response).to be_successful
      expect(@controller.view_assigns["title"]).to eq(title)
      [story1, story2, story3].each do |story|
        expect(@controller.view_assigns["stories"]).to include(story)
      end
      expect(@controller.view_assigns["stories"]).not_to include(story4)
    end
  end

  describe "#top" do
    let!(:old_story) { create(:story, created_at: 10.days.ago, updated_at: 10.days.ago) }
    let(:recent_stories) do
      # Create descending by score so they are sorted in this order from controller
      num = StoriesPaginator::STORIES_PER_PAGE + 5
      Array.new(num) { |n| create :story, score: (num - n) }
    end

    describe "/top redirect" do
      it "redirects to default length path" do
        get :top

        expect(response).to redirect_to("/top/1w")
      end
    end

    describe "/top/rss redirect" do
      it "redirects default length path maintaining format" do
        get :top, format: "rss"

        expect(response).to redirect_to("/top/1w.rss")
      end
    end

    describe "/categories/:category" do
      let(:tag1) { create :tag }
      let(:tag2) { create :tag }

      let!(:category1) { create(:category, tags: [tag1]) }
      let!(:category2) { create(:category, tags: [tag2]) }

      let!(:story1) { create(:story, user:, tags: [tag1]) }
      let!(:story2) { create(:story, user:, tags: [tag2]) }

      it "shows stories for categories only" do
        categories = [category1]

        get :category, params: {category: categories.map(&:category).join(",")}

        expect(response).to be_successful
        expect(@controller.view_assigns["title"]).to eq categories.map(&:category).join(" ")
        expect(@controller.view_assigns["stories"]).to include(story1)
        expect(@controller.view_assigns["stories"]).not_to include(story2)
      end

      it "raises RecordNotFound error when unknown category has been passed" do
        categories = [category1.category, category2.category, "unknown-category"]

        expect { get :category, params: {category: categories.join(",")} }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "/top/:length" do
      it "renders HTML page successfully for 1 week" do
        get :top, params: {length: "1w"}

        expect(response).to be_successful
        expect(response.content_type).to include("text/html")
        expect(@controller.view_assigns["title"]).to eq("Top Stories of the Past Week")
        expect(@controller.view_assigns["rss_link"]).to eq(
          title: "RSS 2.0 - Top Stories of the Past Week",
          href: "/top/1w/rss"
        )
        expect(@controller.view_assigns["stories"]).to include(story)
        expect(@controller.view_assigns["stories"]).not_to include(old_story)
      end
    end

    describe "/top/:length/rss" do
      it "returns RSS feed successfully for 1 week" do
        get :top, format: "rss", params: {length: "1w"}

        expect(response).to be_successful
        expect(response.content_type).to include("application/rss+xml")
        expect(@controller.view_assigns["title"]).to eq("Top Stories of the Past Week")
        expect(@controller.view_assigns["stories"]).to include(story)
        expect(@controller.view_assigns["stories"]).not_to include(old_story)
      end
    end

    describe "/top/:length/page/2" do
      before { recent_stories }

      it "returns HTML data for page 2 with 1 week length" do
        get :top, params: {length: "1w", page: "2"}

        expect(response).to be_successful
        expect(response.content_type).to include("text/html")
        expect(@controller.view_assigns["title"]).to eq("Top Stories of the Past Week")
        expect(@controller.view_assigns["rss_link"]).to eq(
          title: "RSS 2.0 - Top Stories of the Past Week",
          href: "/top/1w/rss"
        )
        expect(@controller.view_assigns["stories"]).to include(recent_stories[StoriesPaginator::STORIES_PER_PAGE + 1])
        expect(@controller.view_assigns["stories"]).not_to include(old_story)
      end
    end

    describe "/top/:length/page/2/rss" do
      before { recent_stories }

      it "returns RSS feed for page 2 with 1 week length" do
        get :top, format: "rss", params: {length: "1w", page: "2"}

        expect(response).to be_successful
        expect(response.content_type).to include("application/rss+xml")
        expect(@controller.view_assigns["title"]).to eq("Top Stories of the Past Week")
        expect(@controller.view_assigns["stories"]).to include(recent_stories[StoriesPaginator::STORIES_PER_PAGE + 1])
        expect(@controller.view_assigns["stories"]).not_to include(old_story)
      end
    end
  end
end
