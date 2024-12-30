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
