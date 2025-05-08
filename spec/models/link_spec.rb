# typed: false

require "rails_helper"

RSpec.describe Link, type: :model do
  describe "url=" do
    it "hydrates normalized_url" do
      expect(Link.new(url: "https://example.com").normalized_url).to eq("example.com")
      expect(Link.new(url: "https://example.com/foo").normalized_url).to eq("example.com/foo")
    end
  end

  describe "url validation" do
    it "doesn't accept js placeholder" do
      l = Link.new url: "#"
      expect(l).to_not be_valid
      expect(l.errors[:url]).to include("is not valid")
    end
  end

  describe "recreate_from_comment!" do
    it "creates Links from comment text" do
      c = create(:comment, comment: "[l1](https://a.com) [l2](https://b.net)")
      expect(Link.where(from_comment: c).pluck(:url).sort).to eq(["https://a.com", "https://b.net"])
    end

    it "Links bare URLs" do
      c = create(:comment, comment: "visit https://a.com sometime")
      expect(c.links.count).to eq(1)
      expect(c.links.last.url).to eq("https://a.com")
    end

    it "only Links once from a comment to a url" do
      c = create(:comment, comment: "A [l1](https://a.com) [l2](https://a.com) https://a.com")
      expect(c.links.count).to eq(1)
      expect(c.links.last.url).to eq("https://a.com")
    end

    it "recognizes a short link to a site comment" do
      target = create(:comment)
      c = create(:comment, comment: "see [redir](https://#{Rails.application.domain}#{Routes.comment_short_id_path(target)})")
      link = c.links.last
      expect(link.url).to end_with(Routes.comment_short_id_path(target))
      expect(link.to_comment_id).to eq(target.id)
    end

    it "recognizes a #c_abc123 link to a site comment" do
      target = create(:comment)
      c = create(:comment, comment: "see [anchor](https://#{Rails.application.domain}#{Routes.comment_target_path(target, true)})")
      link = c.links.last
      expect(link.url).to end_with(Routes.comment_target_path(target, true))
      expect(link.to_comment_id).to eq(target.id)
    end

    it "recognizes a link to a site story by short id" do
      target = create(:story)
      c = create(:comment, comment: "see [story](https://#{Rails.application.domain}#{Routes.story_short_id_path(target)})")
      link = c.links.last
      expect(link.url).to end_with(Routes.story_short_id_path(target))
      expect(link.to_story_id).to eq(target.id)
    end

    it "recognizes a link to a site story by title url" do
      target = create(:story)
      c = create(:comment, comment: "see [story](https://#{Rails.application.domain}#{Routes.title_path(target)})")
      link = c.links.last
      expect(link.url).to end_with(Routes.title_path(target))
      expect(link.to_story_id).to eq(target.id)
    end

    it "only Links once from a comment to a comment" do
      target = create(:comment)
      link = "https://#{Rails.application.domain}#{Routes.comment_target_path(target, true)}"
      c = create(:comment, comment: "#{link} #{link}")
      expect(c.links.count).to eq(1)
      expect(c.links.last.to_comment_id).to eq(target.id)
    end

    it "doesn't duplicate Links in edits" do
      c = create(:comment, comment: "Use [tabs](https://a.com)")
      expect(c.links.count).to eq(1)
      expect(c.links.last.url).to eq("https://a.com")

      c.comment = "Use [spaces](https://a.com)"
      c.save!
      expect(c.links.count).to eq(1)
      link = c.links.last
      expect(link.title).to eq("spaces")
      expect(link.url).to eq("https://a.com")
    end

    it "removes old Links" do
      c = create(:comment, comment: "A [link](https://a.com)")
      expect(c.links.count).to eq(1)
      expect(c.links.last.url).to eq("https://a.com")

      c.comment = "B [link](https://b.com)"
      c.save!
      expect(c.links.count).to eq(1)
      expect(c.links.last.url).to eq("https://b.com")
    end
  end

  # very similar code, so I'm not retesting all the behavior covered by recreate_from_comment!
  describe "recreate_from_story!" do
    it "links from story url" do
      s = create(:story, url: "https://s.dev")
      expect(s.links.count).to eq(1)
      expect(s.links.last.url).to eq("https://s.dev")
    end

    it "links from story description" do
      s = create(:story, url: nil, description: "visit https://s.dev")
      expect(s.links.count).to eq(1)
      expect(s.links.last.url).to eq("https://s.dev")
    end
  end
end
