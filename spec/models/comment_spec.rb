# typed: false

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

  it "sends reply notification" do
    recipient = create(:user)
    recipient.settings["email_notifications"] = true
    recipient.settings["email_replies"] = true

    sender = create(:user)
    # Story under which the comments are posted.
    story = create(:story)

    # Parent comment.
    c = build(:comment, story: story, user: recipient)
    c.save! # Comment needs to get an ID so it can have a child (c2).

    # Reply comment.
    c2 = build(:comment, story: story, user: sender, parent_comment: c)
    c2.save!

    expect(sent_emails.size).to eq(1)
    expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
  end

  it "sends mention notification" do
    recipient = create(:user)
    recipient.settings["email_notifications"] = true
    recipient.settings["email_mentions"] = true
    recipient.save!

    sender = create(:user)
    c = build(:comment, user: sender, comment: "@#{recipient.username}")

    c.save!
    expect(sent_emails.size).to eq(1)
    expect(sent_emails[0].subject).to match(/Mention from #{sender.username}/)
  end

  it "also sends mentions with ~username" do
    recipient = create(:user)
    recipient.settings["email_notifications"] = true
    recipient.settings["email_mentions"] = true
    recipient.save!

    c = build(:comment, comment: "~#{recipient.username}")
    c.save!
    expect(sent_emails.size).to eq(1)
  end

  it "sends only reply notification on reply with mention" do
    # User being mentioned and replied to.
    recipient = create(:user)
    recipient.settings["email_notifications"] = true
    recipient.settings["email_mentions"] = true
    recipient.settings["email_replies"] = true
    # Need to save, because deliver_mention_notifications re-fetches from DB.
    recipient.save!

    sender = create(:user)
    # The story under which the comments are posted.
    story = create(:story)
    # The parent comment.
    c = build(:comment, user: recipient, story: story)
    c.save! # Comment needs to get an ID so it can have a child (c2).

    # The child comment.
    c2 = build(:comment, user: sender, story: story, parent_comment: c,
      comment: "@#{recipient.username}")
    c2.save!

    expect(sent_emails.size).to eq(1)
    expect(sent_emails[0].subject).to match(/Reply from #{sender.username}/)
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
      c.delete_for_user(mod, "Troll")
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

  describe "confidence_order_path" do
    it "doesn't sort comments under the wrong parents when they haven't been voted on" do
      story = create(:story)
      a = create(:comment, story: story, parent_comment: nil)
      create(:comment, story: story, parent_comment: nil)
      c = create(:comment, story: story, parent_comment: a)
      sorted = Comment.story_threads(story)
      # don't care if a or b is first, just care that c is immediately after a
      # this uses each_cons to get each pair of records and ensures [a, c] appears
      relationships = sorted.map(&:id).to_a.each_cons(2).to_a
      expect(relationships).to include([a.id, c.id])
    end
  end
end
