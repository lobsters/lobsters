# typed: false

require "rails_helper"

describe Story do
  it "should get a short id" do
    s = create(:story, title: "hello", url: "http://example.com/")

    expect(s.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  it "has a limit on the markdown description field" do
    s = build(:story)
    s.markeddown_description = "Z" * 16_777_218

    s.valid?
    expect(s.errors[:markeddown_description]).to(
      eq(["is too long (maximum is 16777215 characters)"])
    )
  end

  it "requires a url or a description" do
    expect { create(:story, title: "hello", url: "", description: "") }.to raise_error

    expect {
      create(:story, title: "hello", description: "hi", url: nil)
    }.to_not raise_error

    expect {
      create(:story, title: "hello", url: "http://ex.com/", description: nil)
    }.to_not raise_error
  end

  it "does not allow too-short titles" do
    expect { create(:story, title: "") }.to raise_error
    expect { create(:story, title: "hi") }.to raise_error
    expect { create(:story, title: "hello") }.to_not raise_error
  end

  it "does not allow too-long titles" do
    expect { create(:story, title: ("hello" * 100)) }.to raise_error
  end

  it "must have at least one tag" do
    s = Story.new(tags: [])
    s.valid?
    expect s.errors[:base].select { |e| e.include? "at least one" }.any?

    # passing an empty string to mirror the controller looking up tags by user input
    s = Story.new(tags: Tag.where(tag: ["", "tag1"]))
    s.valid?
    expect s.errors[:base].select { |e| e.include? "at least one" }.none?
  end

  it "removes redundant http port 80 and https port 443" do
    expect(Story.new(url: "http://example.com:80").url).to eq("http://example.com")
    expect(Story.new(url: "http://example.com:80/").url).to eq("http://example.com/")
    expect(Story.new(url: "https://example.com:443").url).to eq("https://example.com")
    expect(Story.new(url: "https://example.com:443/").url).to eq("https://example.com/")
  end

  it "removes utm_ tracking parameters" do
    expect(Story.new(url: "http://a.com?a=b").url).to eq("http://a.com?a=b")
    expect(Story.new(url: "http://a.com?utm_term=track&c=d").url).to eq("http://a.com?c=d")
    expect(Story.new(url: "http://a.com?a=b&utm_term=track&c=d").url).to eq("http://a.com?a=b&c=d")
    expect(Story.new(url: "http://a.com?linkId=track").url).to eq("http://a.com")
  end

  it "checks for invalid urls" do
    expect(Story.new(url: "http://example.com").tap(&:valid?).errors[:url]).to be_empty

    expect(Story.new(url: "http://example/").tap(&:valid?).errors[:url]).to_not be_empty
    expect(Story.new(url: "ftp://example.com/").tap(&:valid?).errors[:url]).to_not be_empty
    expect(Story.new(url: "http://example.com:123/").tap(&:valid?).errors[:url]).to be_empty
  end

  it "checks for a previously posted story with same url" do
    expect(Story.count).to eq(0)

    create(:story, title: "flim flam", url: "http://example.com/")
    expect(Story.count).to eq(1)

    expect {
      create(:story, title: "flim flam 2", url: "http://example.com/")
    }.to raise_error

    expect(Story.count).to eq(1)

    expect {
      create(:story, title: "flim flam 2", url: "http://www.example.com/")
    }.to raise_error

    expect(Story.count).to eq(1)
  end

  it "parses domain properly" do
    story = Story.new
    {
      "http://example.com" => "example.com",
      "https://example.com" => "example.com",
      "http://example.com:8000" => "example.com",
      "http://example.com:8000/" => "example.com",
      "http://www3.example.com/goose" => "example.com",
      "http://flub.example.com" => "flub.example.com",
      "http://www10.org" => "www10.org",
      "http://www10.example.org" => "example.org"
    }.each_pair do |url, domain|
      story.url = url
      expect(story.domain.domain).to eq(domain)
    end
  end

  it "has domain straight out of the db, when Rails doesn't use setters" do
    s = create(:story, url: "https://example.com/foo.html")
    s = Story.find(s.id)
    expect(s.domain.domain).to eq("example.com")
    s.url = "http://example.org"
    expect(s.domain.domain).to eq("example.org")
    s.url = "invalid"
    expect(s.domain).to be_nil
  end

  it "converts a title to a url slug properly" do
    s = create(:story, title: "Hello there, this is a title")
    expect(s.title_as_slug).to eq("hello_there_this_is_title")

    s = create(:story, title: "Hello _ underscore")
    expect(s.title_as_slug).to eq("hello_underscore")

    s = create(:story, title: "Hello, underscore")
    expect(s.title_as_slug).to eq("hello_underscore")

    s = build(:story, title: "The One-second War (What Time Will You Die?) ")
    expect(s.title_as_slug).to eq("one_second_war_what_time_will_you_die")
  end

  it "is not editable by another non-admin user" do
    s = create(:story)
    expect(s.is_editable_by_user?(s.user)).to be true

    u = create(:user)
    expect(s.is_editable_by_user?(u)).to be false
  end

  context "fetching titles" do
    let(:story_directory) { Rails.root.join "spec/fixtures/story_pages/" }

    # this is more elaborate than the previous system, because now it needs to know the content type
    def fake_response(content, type, code = "200")
      res = Net::HTTPResponse.new(1.0, code, "OK")
      res.add_field("content-type", type)
      # we can't seemingly just set body, so...
      allow(res).to receive(:body).and_return(content)
      res
    end

    it "can fetch PDF titles properly" do
      content = File.read(story_directory + "titled.pdf")
      res = fake_response(content, "application/pdf")
      s = build(:story)
      s.fetched_response = res
      expect(s.fetched_attributes[:title]).to eq("Taking a Long Look at QUIC")
    end

    it "can fetch its title properly" do
      content = File.read(story_directory + "title_ampersand.html")
      res = fake_response(content, "text/html")
      s = build(:story)
      s.fetched_response = res
      expect(s.fetched_attributes[:title]).to eq("B2G demo & quick hack // by Paul Rouget")

      content = File.read(story_directory + "title_google.html")
      res = fake_response(content, "text/html")
      s = build(:story)
      s.fetched_response = res
      expect(s.fetched_attributes[:title]).to eq("Google")
    end

    it "does not fetch title with a port specified" do
      expect(Sponge).to_not receive(:new)
      story = Story.new url: "https://example.com:123/"
      expect(story.fetched_attributes[:title]).to eq("")
    end

    it "does not follow rel=canonical when this is to the main page" do
      url = "https://www.mcsweeneys.net/articles/who-said-it-donald-trump-or-regina-george"
      s = build(:story, url: url)
      s.fetched_response = File.read(story_directory + "canonical_root.html")
      expect(s.fetched_attributes[:url]).to eq(url)
    end

    it "does not assign canonical url when the response is non-200" do
      url = "https://www.mcsweeneys.net/a/who-said-it-donald-trump-or-regina-george"
      content = File.read(story_directory + "canonical_error.html")
      res = fake_response(content, "text/html", "404")

      expect_any_instance_of(Sponge)
        .to receive(:fetch)
        .and_return(Net::HTTPResponse.new(1.0, 404, "OK"))

      s = build(:story, url: url)
      s.fetched_response = res
      expect(s.fetched_attributes[:url]).to eq(url)
    end

    it "assigns canonical when url when it resolves 200" do
      url = "https://www.mcsweeneys.net/a/who-said-it-donald-trump-or-regina-george"
      canonical = "https://www.mcsweeneys.net/articles/who-said-it-donald-trump-or-regina-george"
      content = File.read(story_directory + "canonical_error.html")
      res = fake_response(content, "text/html")

      expect_any_instance_of(Sponge)
        .to receive(:fetch)
        .and_return(Net::HTTPResponse.new(1.0, 200, "OK"))

      s = build(:story, url: url)
      s.fetched_response = res
      expect(s.fetched_attributes[:url]).to eq(canonical)
    end

    context "with unicode" do
      it "can fetch unicode titles properly" do
        # Sponge#fetch returns a binary string
        content = "<!DOCTYPE html><html><title>你好世界！ Here’s a fancy apostrophe</title></html>".b
        res = fake_response(content, "text/html")
        s = build(:story)
        s.fetched_response = res
        expect(s.fetched_attributes[:title]).to eq("你好世界！ Here’s a fancy apostrophe")
      end
    end
  end

  it "sets the url properly" do
    s = build(:story, title: "blah")
    s.url = "https://factorable.net/"
    s.valid?
    expect(s.url).to eq("https://factorable.net/")
  end

  it "calculates tag changes properly" do
    s = create(:story, title: "blah", tags: Tag.where(tag: ["tag1", "tag2"]))

    s.tags_was = s.tags.to_a
    s.tags = Tag.where(tag: ["tag2"])
    expect(s.tag_changes).to eq("tags" => ["tag1 tag2", "tag2"])
  end

  it "logs tag additions from user suggestions properly" do
    s = create(:story, title: "blah", tags: Tag.where(tag: ["tag1"]), description: "desc")

    u1 = create(:user)
    s.save_suggested_tags_for_user!(["tag1", "tag2"], u1)
    s.reload

    u2 = create(:user)
    s.save_suggested_tags_for_user!(["tag1", "tag2"], u2)

    mod_log = Moderation.last
    expect(mod_log.moderator_user_id).to eq(nil)
    expect(mod_log.story_id).to eq(s.id)
    expect(mod_log.reason).to match(/Automatically changed/)
    expect(mod_log.action).to match(/tags from "tag1" to "tag1 tag2"/)
  end

  it "logs moderations properly" do
    mod = create(:user, :moderator)

    s = create(:story, title: "blah", tags: Tag.where(tag: ["tag1", "tag2"]),
      description: "desc")

    s.title = "changed title"
    s.description = nil
    s.tags_was = s.tags.to_a
    s.tags = Tag.where(tag: ["tag1"])

    s.editor = mod
    s.moderation_reason = "not about tag2"
    s.save!

    mod_log = Moderation.last
    expect(mod_log.moderator_user_id).to eq(mod.id)
    expect(mod_log.story_id).to eq(s.id)
    expect(mod_log.reason).to eq("not about tag2")
    expect(mod_log.action).to match(/title from "blah" to "changed title"/)
    expect(mod_log.action).to match(/tags from "tag1 tag2" to "tag1"/)
  end

  it "doesn't log changed to derived field normalized_url" do
    mod = create(:user, :moderator)

    s = create(:story, url: "https://example.com/1")

    s.url = "https://example.com/2"
    s.tags_was = s.tags.to_a
    s.editor = mod
    s.moderation_reason = "fixed link"
    s.save!

    mod_log = Moderation.last
    expect(mod_log.story_id).to eq(s.id)
    expect(mod_log.action).to_not match(/normalize/)
  end

  describe "#similar_stories" do
    it "finds stories with similar URLs" do
      s1 = create(:story, url: "https://example.com", created_at: (Story::RECENT_DAYS + 1).days.ago)
      s2 = create(:story, url: "https://example.com/")
      expect(s1.similar_stories).to eq([s2])
      expect(s2.similar_stories).to eq([s1])
    end

    it "does not include merges" do
      s1 = create(:story, url: "https://example.com", created_at: (Story::RECENT_DAYS + 1).days.ago)
      s2 = create(:story, url: "https://example.com/", merged_story_id: s1.id)
      expect(s1.similar_stories).to eq([])
      expect(s2.similar_stories).to eq([])
    end

    it "doesn't throw exceptions at brackets" do
      s = create(:story, url: "http://aaonline.fr/search.php?search&criteria[title-contains]=debian")
      expect(s.similar_stories).to eq([])
    end

    it "finds arxiv html page and pdf URLs with the same arxiv identifier" do
      s1 = create(:story,
        url: "https://arxiv.org/abs/2101.07554",
        created_at: (Story::RECENT_DAYS + 1).days.ago)
      s2 = create(:story, url: "https://arxiv.org/pdf/2101.07554")

      expect(s1.similar_stories).to eq([s2])
      expect(s2.similar_stories).to eq([s1])
    end

    it "finds similar arxiv html page and pdf URLs that contain a pdf extension" do
      s1 = create(:story,
        url: "https://arxiv.org/abs/2101.09188",
        created_at: (Story::RECENT_DAYS + 1).days.ago)
      s2 = create(:story, url: "https://arxiv.org/pdf/2101.09188.pdf")

      expect(s1.similar_stories).to eq([s2])
      expect(s2.similar_stories).to eq([s1])
    end

    it "finds similar www.youtube and youtu.be URLs" do
      s1 = create(:story,
        url: "https://www.youtube.com/watch?v=7Pq-S557XQU",
        created_at: (Story::RECENT_DAYS + 1).days.ago)

      s2 = create(:story, url: "https://youtu.be/7Pq-S557XQU")

      expect(s1.similar_stories).to eq([s2])
      expect(s2.similar_stories).to eq([s1])
    end

    it "finds similar www.youtube and m.youtube URLs" do
      s1 = create(:story,
        url: "https://www.youtube.com/watch?v=7Pq-S557XQU",
        created_at: (Story::RECENT_DAYS + 1).days.ago)

      s2 = create(:story, url: "https://m.youtube.com/watch?v=7Pq-S557XQU")

      expect(s1.similar_stories).to eq([s2])
      expect(s2.similar_stories).to eq([s1])
    end

    it "accepts playlists" do
      s = Story.new(url: "https://www.youtube.com/playlist?list=PLZdCLR02grLpIQQkyGLgIyt0eHE56aJqd")
      s.valid?
      expect(s.errors[:url]).to be_empty
    end
  end

  describe "#calculated_hotness" do
    let(:story) do
      create(:story, url: "https://example.com", user_is_author: true)
    end

    before do
      create(:comment, story: story, score: 1, flags: 5)
      create(:comment, story: story, score: -9, flags: 10)
      # stories stop accepting comments after a while, but this calculation is
      # based on created_at, so set that to a known value after posting comments
      story.update!(created_at: Time.zone.at(0))
    end

    context "with positive base" do
      it "return correct score" do
        expect(story.calculated_hotness).to eq(-0.7271213)
      end
    end

    context "with negative base" do
      before do
        tag = create(:tag, hotness_mod: -10)
        story.update!(tags: [tag])
      end

      it "return correct score" do
        expect(story.calculated_hotness).to eq 9.44897
      end
    end
  end

  describe "update_score_and_recalculate" do
    let(:story) { create(:story) }

    it "deducts from score when users hide and flag" do
      expect(story.score).to eq(1) # from submitter's upvote
      hider = create(:user)
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, nil, hider.id, "S")
      HiddenStory.hide_story_for_user(story, hider)
      expect(story.reload.score).to eq(0)
    end

    it "doesn't deduct from score if hiding user commented" do
      expect(story.score).to eq(1) # from submitter's upvote
      hider = create(:user)
      create(:comment, story: story, user: hider)
      HiddenStory.hide_story_for_user(story, hider)
      expect(story.reload.score).to eq(1)
    end

    it "doesn't deduct from score if hiding user didn't flag" do
      expect(story.score).to eq(1) # from submitter's upvote
      hider = create(:user)
      HiddenStory.hide_story_for_user(story, hider)
      expect(story.reload.score).to eq(1)
    end
  end

  describe "#update_cached_columns" do
    context "with a merged_into_story" do
      let(:merged_into_story) { create(:story) }
      let(:story) { create(:story, merged_into_story: merged_into_story) }

      it "should also update the merged_into_story's comment count" do
        expect(story.comments_count).to eq 0
        expect(merged_into_story.comments_count).to eq 0
        create(:comment, story: story)
        story.update_cached_columns
        expect(story.comments_count).to eq 1
        expect(merged_into_story.comments_count).to eq 1
      end
    end
  end

  describe "#already_posted_recently?" do
    it "returns true when trying to submit a URL that's been submitted w/o an anchor in it" do
      create(:story, url: "https://www.example.com/article.html")
      story_has_url_with_anchor = build(:story, url: "https://www.example.com/article.html#main")

      expect(story_has_url_with_anchor.already_posted_recently?).to be true
    end

    it "returns true when trying to submit a URL that's been submitted with an anchor in it" do
      create(:story, url: "https://www.example.com/article.html#main")
      story_has_url_without_anchor = build(:story, url: "https://www.example.com/article.html")

      expect(story_has_url_without_anchor.already_posted_recently?).to be true
    end
  end

  describe "scopes" do
    context "recent" do
      it "returns the newest stories that have not yet reached the front page" do
        create(:story, title: "Front Page")
        create(:story, title: "Front Page 2")
        flagged = create(:story, title: "New Story", score: -2, flags: 3)
        expect(Story.front_page).to_not include(flagged)

        expect(Story.recent).to include(flagged)
        expect(Story.recent).to_not include(Story.front_page)
      end
    end

    describe "hidden" do
      let(:tag) { create :tag }
      let(:story1) { create(:story, title: "Hello 1", url: "http://example.com/1", tags: [tag]) }
      let(:story2) { create(:story, title: "Hello 2", url: "http://example.com/2", tags: [tag]) }
      let(:user) { create(:user) }

      before do
        create_list(:comment, 2, story: story2, score: 2, flags: 5)
        story1.update!(created_at: Time.zone.at(0))
        story2.update!(created_at: Time.zone.at(0))

        [story1, story2].each { |story| HiddenStory.hide_story_for_user(story, user) }

        Story.recalculate_all_hotnesses!
      end

      context "exclude tags are empty" do
        subject(:stories) { Story.hidden(user) }

        it { expect(stories.size).to eq(2) }

        it { expect(stories.first).to eq(story2) }

        it { expect(stories.last).to eq(story1) }
      end

      context "excluded tags are provided" do
        let(:excluded_tag) { create :tag }
        let!(:story3) { create :story, title: "Hello 3", tags: [excluded_tag] }

        subject(:stories) { Story.hidden(user, [excluded_tag]) }

        it { expect(stories.size).to eq(2) }

        it { expect(stories.first).to eq(story2) }

        it { expect(stories.last).to eq(story1) }
      end
    end

    describe "newest" do
      let(:tag) { create :tag }
      let!(:story1) { create :story, title: "Hello 1", url: "http://example.com/1", tags: [tag] }
      let!(:story2) { create :story, title: "Hello 2", url: "http://example.com/2" }
      let(:user) { create :user }

      context "exclude tags are emtpy" do
        subject(:stories) { Story.newest(user) }

        it "returns two stories" do
          expect(stories.length).to eq(2)
        end

        it "first story in a list is last created" do
          expect(stories.first).to eq(story2)
        end

        it "last story in a list is first created" do
          expect(stories.last).to eq(story1)
        end
      end

      context "exclude tags are provided" do
        subject(:stories) { Story.newest(user, [tag]) }

        it "returns only one story without tag" do
          expect(stories).to eq([story2])
        end
      end
    end

    describe "active" do
      let(:user) { create :user }

      it "is ordered by most-recent comment" do
        older_story = create(:story)
        newer_story = create(:story)
        older_comment = create(:comment, story: newer_story)
        newer_comment = create(:comment, story: older_story)

        expect(Story.active(user)).to eq([newer_comment.story, older_comment.story])
      end

      it "does not show hidden stories" do
        hidden_story = create(:story)
        normal_story = create(:story)
        create(:comment, story: hidden_story)
        normal_comment = create(:comment, story: normal_story)

        HiddenStory.hide_story_for_user(hidden_story, hidden_story.user)
        hidden_story_user = User.find_by(id: hidden_story.user_id)

        expect(Story.active(hidden_story_user)).to eq([normal_comment.story])
      end
    end

    describe "saved" do
      let(:user) { create(:user) }
      let(:first_story) { create(:story) }
      let(:second_story) { create(:story) }

      before do
        create_list(:comment, 2, story: second_story, score: 2)
        [first_story, second_story].each do |story|
          story.update!(created_at: Time.zone.at(0))
        end

        Story.recalculate_all_hotnesses!
      end

      it "is ordered by hotness" do
        [first_story, second_story].each do |story|
          SavedStory.create!(user: user, story: story)
        end

        expect(Story.saved(user)).to eq([second_story, first_story])
      end

      it "shows only saved stories" do
        SavedStory.create!(user: user, story: first_story)

        expect(Story.saved(user)).to eq([first_story])
      end
    end

    describe "newest_by_user" do
      let(:user) { create(:user) }
      let(:submitter) { create(:user) }

      def story_titles_from(submitter:, basic: user)
        Story.newest_by_user(basic, submitter).map(&:title)
      end

      context "when submitter is viewing their own stories" do
        it "sees their stories" do
          create(:story, user: submitter, title: "Own story")
          expect(story_titles_from(submitter:)).to include("Own story")
        end

        it "sees their own deleted stories" do
          create(:story, user: submitter, title: "deleted story", is_deleted: 1)
          expect(story_titles_from(basic: submitter, submitter:)).to include("deleted story")
        end

        it "sees stories that were merged into others' stories" do
          by_other = create(:story, title: "other story")
          create(:story, user: submitter, title: "merged story", merged_into_story: by_other)

          expect(story_titles_from(submitter:)).to include("merged story")
          expect(story_titles_from(submitter:)).to_not include("other story")
        end

        it "sees their own stories merged into a story they submitted" do
          own = create(:story, user: submitter, title: "own story")
          create(:story, user: submitter, title: "merged story", merged_into_story: own)
          expect(story_titles_from(submitter:)).to include("own story")
          expect(story_titles_from(submitter:)).to include("merged story")
        end

        it "does not see stories by others merged into a story they submitted" do
          own = create(:story, user: submitter, title: "own story")
          create(:story, title: "by other", merged_into_story: own)
          expect(story_titles_from(basic: nil, submitter:)).to_not include("by other")
        end
      end

      it "users don't see others' deleted stories" do
        create(:story, user: submitter, title: "deleted story", is_deleted: 1)
        expect(story_titles_from(basic: nil, submitter:)).not_to include("deleted story")
      end
    end

    describe "tagged" do
      let(:user) { create :user }

      it "only selects tagged stories" do
        other_story = create(:story)
        tag = create(:tag)
        story = create(:story, user:, title: "A story", tags: [tag])

        tagged = Story.tagged(user, [tag])

        expect(tagged.count).to be 1
        expect(tagged.first).to eq story
      end

      it "selects unique tagged stories" do
        tag1 = create(:tag)
        tag2 = create(:tag)
        story = create(:story, user:, title: "A story", tags: [tag1, tag2])

        tagged = Story.tagged(user, [tag1, tag2])

        expect(tagged.count).to be 1
        expect(tagged.first).to eq story
      end
    end

    describe "top" do
      let(:user) { create :user }

      it "selects stories from the given interval" do
        create_list :story, 2, user:, created_at: 3.months.ago
        story = create :story, user:, created_at: 2.days.ago

        stories = Story.top(user, dur: 7, intv: "day")

        expect(stories.count).to eq(1)
        expect(stories.first).to eq(story)
      end

      it "raise the ArgumentError exception when inveral unit value is invalid" do
        expect { Story.top(user, dur: 7, intv: "wrong") }.to raise_error(ArgumentError)
      end
    end

    describe ".categories" do
      let(:user) { create :user }

      it "selects unique stories based on categories" do
        tag1 = create(:tag)
        tag2 = create(:tag)
        category = create(:category, tags: [tag1, tag2])
        story = create(:story, user:, title: "A story", tags: [tag1, tag2])

        stories = Story.categories(user, [category])

        expect(stories.count).to eq 1
        expect(stories.first).to eq story
      end
    end
  end

  describe "suggestions" do
    it "replaces a user's suggestion when they suggest again" do
      # ActiveRecord::Base.logger = Logger.new STDOUT

      story = create :story, tags: Tag.where(tag: "tag1")
      user = create(:user)

      # simulate two POSTs to /s/abc123/suggestions
      story.save_suggested_tags_for_user!(["tag2"], user)
      story.save_suggested_tags_for_user!(["tag2"], user)

      story.reload
      expect(story.tags.map(&:tag)).to eq(["tag1"])
    end

    it "does not auto-accept suggestion if quorum is not met" do
      story = create(:story, title: "hello", url: "http://example.com/")
      user = create(:user)

      story.save_suggested_title_for_user!("new title", user)

      expect(story.title).to eq("hello")
    end

    it "auto-accept suggestion once quorum is met" do
      story = create(:story, title: "hello", url: "http://example.com/")
      user1 = create(:user)
      user2 = create(:user)

      story.save_suggested_title_for_user!("new title", user1)
      story.save_suggested_title_for_user!("new title", user2)

      expect(story.title).to eq("new title")
    end

    it "notifies story creator upon auto-accepted suggestion" do
      creator = create(:user)
      story = create(:story, user: creator, title: "hello", url: "http://example.com/")
      user1 = create(:user)
      user2 = create(:user)

      expect(creator.received_messages.length).to eq(0)

      story.save_suggested_title_for_user!("new title", user1)
      story.save_suggested_title_for_user!("new title", user2)

      expect(creator.reload.received_messages.length).to eq(1)
    end
  end

  describe ".title_maximum_length" do
    subject { Story.title_maximum_length }

    it { is_expected.to eq(150) }
  end
end
