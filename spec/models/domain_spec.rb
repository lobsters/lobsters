# typed: false

require "rails_helper"

RSpec.describe Domain, type: :model do
  describe "origin" do
    it "takes a selector and replacement to generate an origin identifier" do
      d = Domain.create! domain: "github.com",
        selector: "\\Ahttps://(github.com/[^/]+).*\\z",
        replacement: "\\1"
      expect(d.find_or_create_origin("https://github.com/foo").identifier).to eq("github.com/foo")
      expect(d.find_or_create_origin("https://github.com/foo/bar").identifier).to eq("github.com/foo")

      expect(d.find_or_create_origin("https://github.com/FOO").identifier).to eq("github.com/foo")

      expect(d.find_or_create_origin("https://github.com/BAZ").identifier).to eq("github.com/baz")
    end

    it "creates a bare-domain origin for bare and trailing slash URLs" do
      d = Domain.create! domain: "github.com",
        selector: "\\Ahttps://(github.com/[^/]+).*\\z",
        replacement: "\\1"
      expect(d.find_or_create_origin("https://github.com/").identifier).to eq("github.com")
      expect(d.find_or_create_origin("https://github.com").identifier).to eq("github.com")
    end

    it "inserts start-and-end-of-line anchors to " do
      d = Domain.new domain: "github.com",
        selector: "https://github.com" # not a working selector
      expect(d.selector).to eq("\\Ahttps://github.com\\z")
    end

    it "has a timeout on selector_regexp" do
      d = Domain.new domain: "github.com",
        selector: "https://github.com"
      expect(d.selector_regexp.timeout).to be(0.1)
    end

    it "is invalid for invalid regexp" do
      d = Domain.new domain: "github.com",
        selector: "\\Ahttps://(github.com/[^/]+.*\\z", # missing ) on capture
        replacement: "\\1"
      expect(d.valid?).to be(false)
      expect(d.errors[:selector].first).to include("invalid Regexp")
    end

    it "updates Origins on existing Stories if selector changes" do
      story = create(:story, url: "https://example.com/foo/bar")
      domain = story.domain
      domain.selector = "\\Ahttps://(example.com/[^/]+).*\\z"
      domain.replacement = "\\1"
      domain.save!

      # origin created
      origin = domain.origins.last
      expect(origin.identifier).to eq("example.com/foo")

      # story updated with origin
      expect(story.reload.origin).to eq(origin)
    end

    it "can share an Origin between Domains" do
      github = create(:domain, :github_with_selector)
      pages = create(:domain, domain: "foo.github.io",
        selector: "\\Ahttps?://foo.github.io.*\\z",
        replacement: "github.com/foo")

      from_github = github.find_or_create_origin("https://github.com/foo/bar")
      from_pages = pages.find_or_create_origin("https://foo.github.io/bar")

      expect(from_pages).to be_persisted
      expect(from_pages).to eq(from_github)
      expect(from_pages.domain).to eq(github)
    end

    it "falls back to the submitting Domain when no Domain matches the identifier" do
      pages = create(:domain, domain: "foo.github.io",
        selector: "\\Ahttps?://foo.github.io.*\\z",
        replacement: "github.com/foo")

      origin = pages.find_or_create_origin("https://foo.github.io/bar")

      expect(origin.identifier).to eq("github.com/foo")
      expect(origin.domain).to eq(pages)
    end

    it "re-points the Domain when the identifier changes" do
      github = create(:domain, :github_with_selector)
      pages = create(:domain, domain: "foo.github.io",
        selector: "\\Ahttps?://foo.github.io.*\\z",
        replacement: "foo.github.io")
      origin = pages.find_or_create_origin("https://foo.github.io/bar")
      expect(origin.domain).to eq(pages)

      origin.identifier = "github.com/foo"

      expect(origin.domain).to eq(github)
    end

    it "attaches a Story to an Origin owned by another Domain" do
      create(:domain, :github_with_selector).find_or_create_origin("https://github.com/foo")
      pages = create(:domain, domain: "foo.github.io",
        selector: "\\Ahttps?://foo.github.io.*\\z",
        replacement: "github.com/foo")

      story = create(:story, url: "https://foo.github.io/bar")

      expect(story.reload.origin).to eq(Origin / "github.com/foo")
      expect(pages.reload.stories_count).to eq(1)
    end
  end

  describe "merging Origins deduplicates" do
    let!(:domain) {
      create(:domain, domain: "medium.com",
        selector: "\\Ahttps?://medium.com/+([^/]+).*\\z",
        replacement: "medium.com/\\1")
    }
    let(:fixed_selector) { "\\Ahttps?://medium.com/@?+([^/]+).*\\z" }
    let(:mod) { create(:user) }

    it "moves the Stories onto one Origin and deletes the empty" do
      at = create(:story, url: "https://medium.com/@author/aaa", created_at: 3.years.ago)
      expect(at.origin.identifier).to eq("medium.com/@author")
      bare = create(:story, url: "https://medium.com/author/bbb", created_at: 1.year.ago)
      expect(bare.origin.identifier).to eq("medium.com/author")

      domain.update! selector: fixed_selector

      origin = Origin.find_by identifier: "medium.com/author"
      expect(domain.origins.reload.pluck(:identifier)).to eq(["medium.com/author"])
      expect([at.reload.origin, bare.reload.origin]).to eq([origin, origin])
      expect(origin.stories_count).to eq(2)
      expect(domain.reload.stories_count).to eq(2)
      expect(origin.created_at).to eq(at.created_at)
    end

    it "carries a ban and its modlog onto the Origin that remains" do
      create(:story, url: "https://medium.com/@author/aaa")
      create(:story, url: "https://medium.com/author/bbb")
      merged = Origin / "medium.com/@author"
      merged.ban_by_user_for_reason!(mod, "spam")
      moderation = Moderation.find_by!(origin_id: merged.id)

      domain.update! selector: fixed_selector

      origin = Origin.find_by identifier: "medium.com/author"
      expect(Origin.find_by(identifier: "medium.com/@author")).to be_nil
      expect(origin).to be_banned
      expect(origin.banned_reason).to eq("spam")
      expect(origin.banned_by_user_id).to eq(mod.id)
      expect(moderation.reload.origin).to eq(origin)
      expect([moderation.action, moderation.reason]).to eq(["Banned", "spam"])
    end
  end

  describe "ban" do
    let(:user) { create(:user) }
    let(:domain) { create(:domain) }

    before do
      domain.ban_by_user_for_reason!(user, "Test reason")
    end

    describe "should be banned" do
      it "has correct banned_at" do
        expect(domain.banned_at).not_to be nil
      end

      it "has correct banned_by_user_id" do
        expect(domain.banned_by_user_id).to eq user.id
      end

      it "has correct banned_reason" do
        expect(domain.banned_reason).to eq "Test reason"
      end
    end

    describe "should have moderation" do
      before do
        @moderation = Moderation.find_by(domain: domain)
      end

      it "moderation should be created" do
        expect(@moderation).not_to be nil
      end

      it "has correct moderator_user_id" do
        expect(@moderation.moderator_user_id).to eq user.id
      end

      it "has correct action" do
        expect(@moderation.action).to eq "Banned"
      end

      it "has correct reason" do
        expect(@moderation.reason).to eq "Test reason"
      end
    end
  end

  describe "unban" do
    let(:user) { create(:user) }
    let(:domain) {
      create(
        :domain,
        banned_at: Time.current,
        banned_by_user_id: user.id,
        banned_reason: "test reason"
      )
    }

    before do
      domain.unban_by_user_for_reason!(user, "Test reason")
    end

    describe "should be unbanned" do
      it "has empty banned_at" do
        expect(domain.banned_at).to be nil
      end

      it "has empty banned_by_user_id" do
        expect(domain.banned_by_user_id).to be nil
      end

      it "has empty banned_reason" do
        expect(domain.banned_reason).to be nil
      end
    end

    describe "should have moderation" do
      before do
        @moderation = Moderation.find_by(domain: domain)
      end

      it "moderation should be created" do
        expect(@moderation).not_to be nil
      end

      it "has correct moderator_user_id" do
        expect(@moderation.moderator_user_id).to eq user.id
      end

      it "has correct action" do
        expect(@moderation.action).to eq "Unbanned"
      end

      it "has correct reason" do
        expect(@moderation.reason).to eq "Test reason"
      end
    end
  end
end
