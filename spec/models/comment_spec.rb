require "rails_helper"

describe Comment do
  it "should get a short id" do
    c = create(:comment)

    expect(c.short_id).to match(/^\A[a-zA-Z0-9]{1,10}\z/)
  end

  describe "hat" do
    it "can't be worn if user doesn't have that hat" do
      comment = build(:comment, hat: build(:hat))
      comment.valid?
      expect(comment.errors[:hat]).to eq(["not wearable by user"])
    end

    it "can be one of the user's hats" do
      hat = create(:hat)
      user = hat.user
      comment = create(:comment, user: user, hat: hat)
      comment.valid?
      expect(comment.errors[:hat]).to be_empty
    end

    it "logs hat use on new comment" do
      hat = create(:hat, modlog_use: true)
      user = hat.user
      comment = build(:comment, user: user, hat: hat)

      expect { comment.save! }
        .to change { Moderation.count }.by(1)

      modlog = Moderation.last
      expect(modlog.moderator).to eq(user)
      expect(modlog.comment).to eq(comment)
      expect(modlog.action).to eq("used #{hat.hat} hat")
    end

    it "logs hat use on edited comment that adds it" do
      hat = create(:hat, modlog_use: true)
      user = hat.user
      comment = build(:comment, user: user)

      expect { comment.save! }
        .to_not change { Moderation.count }

      comment.hat = hat
      expect { comment.save! }
        .to change { Moderation.count }.by(1)

      modlog = Moderation.last
      expect(modlog.moderator).to eq(user)
      expect(modlog.comment).to eq(comment)
      expect(modlog.action).to eq("used #{hat.hat} hat")
    end

    it "doesn't relog hat use on edit that doesn't change hat" do
      hat = create(:hat, modlog_use: true)
      user = hat.user
      comment = build(:comment, user: user, hat: hat)
      expect { comment.save! }
        .to change { Moderation.count }.by(1)

      modlog = Moderation.last
      expect(modlog.moderator).to eq(user)
      expect(modlog.comment).to eq(comment)
      expect(modlog.action).to eq("used #{hat.hat} hat")

      comment.comment = "edited"
      expect { comment.save! }
        .to_not change { Moderation.count }
    end
  end

  it "validates the length of short_id" do
    comment = Comment.new(short_id: "01234567890")
    expect(comment).to_not be_valid
  end

  it "is not valid without a comment" do
    comment = Comment.new(comment: nil)
    expect(comment).to_not be_valid
  end

  it "validates the length of markeddown_comment" do
    comment = build(:comment, markeddown_comment: "a" * 16_777_216)
    expect(comment).to_not be_valid
  end

  it "extracts links from markdown" do
    c = Comment.new comment: "a [link](https://example.com)"

    # smoke test:
    expect(c.markeddown_comment).to eq("<p>a <a href=\"https://example.com\" rel=\"ugc\">link</a></p>\n")

    links = c.parsed_links
    expect(links.count).to eq(1)
    l = links.last
    expect(l.url).to eq("https://example.com")
    expect(l.title).to eq("link")
  end

  it "links to users during and after creation" do
    create(:user, username: "alice", created_at: 2.weeks.ago)
    c = Comment.new(
      user: create(:user),
      story: create(:story),
      comment: "hello @alice and @bob"
    )

    expect(c.created_at).to be_nil
    expect(c.generated_markeddown_comment).to eq("<p>hello <a href=\"https://lobste.rs/~alice\" rel=\"ugc\">@alice</a> and @bob</p>\n")

    c.save!
    expect(c.created_at).not_to be_nil
    expect(c.generated_markeddown_comment).to eq("<p>hello <a href=\"https://lobste.rs/~alice\" rel=\"ugc\">@alice</a> and @bob</p>\n")
  end

  describe ".tokenize" do
    it "tokenizes using comments_fts" do
      a = create(:comment, comment: "Café NAÏVE foo-bar, foo isn't 62 the")
      b = create(:comment, comment: "!! -- ... at")

      a_tokens, b_tokens = Comment.tokenize([a, b])

      expect(a_tokens.comment).to eq(a)
      expect(a_tokens.tokens.sort).to eq(%w[bar cafe foo foo isn naive the])
      expect(a_tokens.terms).to eq(%w[bar cafe foo isn naive the])
      expect(a_tokens.count).to eq(7)

      expect(b_tokens.comment).to eq(b)
      expect(b_tokens.tokens).to eq([])
    end
  end

  describe ".accessible_to_user" do
    it "when user is a moderator" do
      moderator = build(:user, :moderator)

      expect(Comment.accessible_to_user(moderator)).to eq(Comment.all)
    end

    it "when user does not a moderator" do
      user = build(:user)

      expect(Comment.accessible_to_user(user)).to eq(Comment.active)
    end
  end

  it "subtracts karma if mod intervenes" do
    author = create(:user)
    voter = create(:user)
    mod = create(:user, :moderator)
    c = create(:comment, user: author)
    expect {
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, c.story_id, c.id, voter.id, nil)
    }.to change { author.reload.karma }.by(1)
    expect {
      c.delete_by_moderator(mod, "Troll")
    }.to change { author.reload.karma }.by(-4)
  end

  describe "speed limit" do
    let(:story) { create(:story) }
    let(:author) { create(:user) }

    it "is not enforced as a regular validation" do
      parent = create(:comment, story: story, user: author, created_at: 30.seconds.ago)
      c = Comment.new(
        user: author,
        story: story,
        parent_comment: parent,
        comment: "good times"
      )
      expect(c.valid?).to be true
    end

    it "is not enforced on top level, only replies" do
      create(:comment, story: story, user: author, created_at: 30.seconds.ago)
      c = Comment.new(
        user: author,
        story: story,
        comment: "good times"
      )
      expect(c.breaks_speed_limit?).to be false
    end

    it "limits within 2 minutes" do
      top = create(:comment, story: story, user: author, created_at: 90.seconds.ago)
      mid = create(:comment, story: story, parent_comment: top, created_at: 60.seconds.ago)
      c = Comment.new(
        user: author,
        story: story,
        parent_comment: mid,
        comment: "too fast"
      )
      expect(c.breaks_speed_limit?).to be_truthy
    end

    it "limits longer with flags" do
      top = create(:comment, story: story, user: author, created_at: 150.seconds.ago)
      mid = create(:comment, story: story, parent_comment: top, created_at: 60.seconds.ago)
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story, mid, create(:user).id, "T")
      c = Comment.new(
        user: author,
        story: story,
        parent_comment: mid,
        comment: "too fast"
      )
      expect(c.breaks_speed_limit?).to be_truthy
    end

    it "has an extra message if author flagged a parent" do
      top = create(:comment, story: story, user: author, created_at: 200.seconds.ago)
      mid = create(:comment, story: story, parent_comment: top, created_at: 60.seconds.ago)
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story, mid, author.id, "T")
      c = Comment.new(
        user: author,
        story: story,
        parent_comment: mid,
        comment: "too fast"
      )
      expect(c.breaks_speed_limit?).to be_truthy
      expect(c.errors[:comment].join(" ")).to include("You flagged")
    end

    it "doesn't limit slow responses" do
      top = create(:comment, story: story, user: author, created_at: 20.minutes.ago)
      mid = create(:comment, story: story, parent_comment: top, created_at: 60.seconds.ago)
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story, mid, author.id, "T")
      c = Comment.new(
        user: author,
        story: story,
        parent_comment: mid,
        comment: "too fast"
      )
      expect(c.breaks_speed_limit?).to be false
    end
  end

  describe "confidence" do
    it "is low for flagged comments" do
      conf = Comment.new(score: -4, flags: 5).calculated_confidence
      expect(conf).to be < 0.3
    end

    it "it is high for upvoted comments" do
      conf = Comment.new(score: 100, flags: 0).calculated_confidence
      expect(conf).to be > 0.75
    end

    it "at the scame score, is higher for comments without flags" do
      upvoted = Comment.new(score: 10, flags: 0).calculated_confidence
      flagged = Comment.new(score: 10, flags: 4).calculated_confidence
      expect(upvoted).to be > flagged
    end
  end

  describe "#parents" do
    it "returns ancestors root-first" do
      story = create(:story)
      root = create(:comment, story: story)
      mid = create(:comment, story: story, parent_comment: root)
      leaf = create(:comment, story: story, parent_comment: mid)

      expect(root.parents).to be_empty
      expect(leaf.parents.map(&:id)).to eq([root.id, mid.id])
      expect(leaf.parents.map(&:depth)).to eq([0, 1])
    end
  end

  describe ".recent_threads" do
    it "shows whole threads the user commented in, newest thread first" do
      user = create(:user)
      story = create(:story)
      old_root = create(:comment, story:)
      old_reply = create(:comment, story:, parent_comment: old_root, user:)
      old_popular_reply = create(:comment, story:, parent_comment: old_root, create_votes: 3)
      create(:comment, story:) # thread without the user
      new_root = create(:comment, story:, user:)
      new_reply = create(:comment, story:, parent_comment: new_root)

      expect(Comment.recent_threads(user))
        .to eq([new_root, new_reply, old_root, old_popular_reply, old_reply])
    end
  end

  describe ".story_threads" do
    it "orders by depth, then confidence" do
      story = create(:story)
      low = create(:comment, story:, create_votes: 2)
      high = create(:comment, story:, create_votes: 5)
      low_low = create(:comment, story:, parent_comment: low)
      low_high = create(:comment, story:, parent_comment: low, create_votes: 3)
      low_low_low = create(:comment, story:, parent_comment: low_low)
      high_low = create(:comment, story:, parent_comment: high)

      expect(Comment.story_threads([story]))
        .to eq([high, high_low, low, low_high, low_low, low_low_low])
    end

    it "shows the earlier of tied siblings first" do
      story = create(:story)
      earlier = create(:comment, story:)
      later = create(:comment, story:)

      expect(Comment.story_threads([story])).to eq([earlier, later])
    end

    it "shows each story's comments together, in the order the stories were given" do
      story = create(:story)
      merged = create(:story, merged_into_story: story)
      on_merged = create(:comment, story: merged, create_votes: 5)
      on_story = create(:comment, story:)
      reply_on_merged = create(:comment, story: merged, parent_comment: on_merged)

      expect(Comment.story_threads([story, merged])).to eq([on_story, on_merged, reply_on_merged])
      expect(Comment.story_threads([merged, story])).to eq([on_merged, reply_on_merged, on_story])
    end

    it "counts the comments of each story as thread_size" do
      story = create(:story)
      merged = create(:story, merged_into_story: story)
      create(:comment, story:)
      create_list(:comment, 2, story: merged)

      expect(Comment.story_threads([story, merged]).map(&:thread_size)).to eq([1, 2, 2])
    end

    it "keeps thread order when joined to other tables" do
      story = create(:story)
      low = create(:comment, story:)
      high = create(:comment, story:, create_votes: 1)
      reply = create(:comment, story:, parent_comment: high)

      threads = Comment.story_threads([story])

      expect(threads.joins(:story).merge(Story.not_deleted(nil))).to eq([high, reply, low])
      expect(threads.eager_load(:user, :story)).to eq([high, reply, low])
    end

    it "is empty for no stories or an unsaved story" do
      expect(Comment.story_threads([])).to be_empty
      expect(Comment.story_threads([build(:story)])).to be_empty
    end
  end
end
