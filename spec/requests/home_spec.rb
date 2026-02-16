# typed: false

require "rails_helper"

describe "home", type: :request do
  describe "#category" do
    it "lists stories in the category" do
      story = create(:story)
      get "/categories/#{story.tags.first.category.category}"

      expect(response).to be_successful
      expect(response.body).to include(story.title)
    end
  end

  describe "#for_domain" do
    it "returns 404 for non-existent domain" do
      expect { get "/domains/unseen.domain" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns 200 for existing domains" do
      story = create(:story)
      get "/domains/#{story.domain.domain}"

      expect(response).to be_successful
      expect(response.body).to include(story.title)
    end

    it "redirects old singular routes" do
      get "/domain/example.com"
      expect(response).to redirect_to("/domains/example.com")

      get "/domain/example.com/page/2"
      expect(response).to redirect_to("/domains/example.com/page/2")
    end
  end

  describe "#newest_by_user" do
    it "shows a merge icon for merged stories" do
      by_other = create(:story)
      alice = create(:user, username: "alice")
      create(:story, user: alice, merged_into_story: by_other)

      get "/~alice/stories"
      expect(response.body).to include('<span class="merge">')
    end
  end

  describe "rss" do
    it "renders" do
      link = create(:story)
      text = create(:story, url: nil, description: "text post")

      get "/rss"
      expect(response).to be_successful
      expect(response.body).to include(link.title)
      expect(response.body).to include(text.title)
    end
  end

  describe "tag combination filters" do
    let(:user) { create(:user) }
    let(:tag1) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:tag3) { create(:tag) }

    context "when logged in" do
      before do
        sign_in user
      end

      it "applies combination filters to front page stories" do
        story_filtered = create(:story, tags: [tag1, tag2], score: 10)
        story_visible = create(:story, tags: [tag1], score: 10)

        user.tag_filter_combinations.create!(tags: [tag1, tag2])

        get "/"

        expect(response).to be_successful
        expect(response.body).to include(story_visible.title)
        expect(response.body).not_to include(story_filtered.title)
      end

      it "works with multiple combination filters" do
        story1 = create(:story, tags: [tag1, tag2], score: 10)
        story2 = create(:story, tags: [tag2, tag3], score: 10)
        story3 = create(:story, tags: [tag1], score: 10)
        story4 = create(:story, tags: [tag3], score: 10)

        user.tag_filter_combinations.create!(tags: [tag1, tag2])
        user.tag_filter_combinations.create!(tags: [tag2, tag3])

        get "/"

        expect(response).to be_successful
        expect(response.body).to include(story3.title)
        expect(response.body).to include(story4.title)
        expect(response.body).not_to include(story1.title)
        expect(response.body).not_to include(story2.title)
      end

      it "works with both tag filters and combination filters" do
        user.tag_filters.create!(tag: tag3)
        user.tag_filter_combinations.create!(tags: [tag1, tag2])

        story_combo_filtered = create(:story, tags: [tag1, tag2], score: 10)
        story_tag_filtered = create(:story, tags: [tag3], score: 10)
        story_visible = create(:story, tags: [tag1], score: 10)

        get "/"

        expect(response).to be_successful
        expect(response.body).to include(story_visible.title)
        expect(response.body).not_to include(story_combo_filtered.title)
        expect(response.body).not_to include(story_tag_filtered.title)
      end

      it "does not filter when user has no combination filters" do
        story1 = create(:story, tags: [tag1, tag2], score: 10)
        story2 = create(:story, tags: [tag1], score: 10)

        get "/"

        expect(response).to be_successful
        expect(response.body).to include(story1.title)
        expect(response.body).to include(story2.title)
      end
    end

    context "when logged out" do
      it "does not apply filters for logged out users" do
        story_combo = create(:story, tags: [tag1, tag2], score: 10)
        story_single = create(:story, tags: [tag1], score: 10)

        user.tag_filter_combinations.create!(tags: [tag1, tag2])

        get "/"

        expect(response).to be_successful
        expect(response.body).to include(story_combo.title)
        expect(response.body).to include(story_single.title)
      end
    end
  end
end
