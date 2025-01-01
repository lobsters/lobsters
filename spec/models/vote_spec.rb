# typed: false

require "rails_helper"

describe Vote do
  it "is not valid without a vote amount" do
    s = create(:story)
    u = create(:user)
    v = build(:vote, user: u, story: s, vote: nil)

    v.valid?
    expect(v.errors[:vote]).to include("can't be blank")
  end

  context "upvoting a story and flags" do
    # don't need to test short-circuit where vote is "changed" to what it already is

    let(:u) { create(:user) }
    let(:s) { create(:story) }

    it "-1 to 1" do
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, s.id, nil, u.id, "S")
      s.reload
      expect(s.score).to eq(1)
      expect(s.flags).to eq(1)
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)
      s.reload
      expect(s.score).to eq(2)
      expect(s.flags).to eq(0)
    end

    it "-1 to 0" do
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, s.id, nil, u.id, "S")
      s.reload
      expect(s.score).to eq(1)
      expect(s.flags).to eq(1)
      Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id, nil, u.id, nil)
      s.reload
      expect(s.score).to eq(1)
      expect(s.flags).to eq(0)
    end

    it "0 to 1" do
      expect(s.score).to eq(1)
      expect(s.flags).to eq(0)
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)
      s.reload
      expect(s.score).to eq(2)
      expect(s.flags).to eq(0)
    end

    it "1 to 0" do
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)
      s.reload
      expect(s.score).to eq(2)
      expect(s.flags).to eq(0)
      Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id, nil, u.id, nil)
      s.reload
      expect(s.score).to eq(1)
      expect(s.flags).to eq(0)
    end

    it "0 to -1" do
      expect(s.score).to eq(1)
      expect(s.flags).to eq(0)
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, s.id, nil, u.id, "S")
      s.reload
      expect(s.score).to eq(1)
      expect(s.flags).to eq(1)
    end

    it "1 to -1" do
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)
      s.reload
      expect(s.score).to eq(2)
      expect(s.flags).to eq(0)
      Vote.vote_thusly_on_story_or_comment_for_user_because(-1, s.id, nil, u.id, "S")
      s.reload
      expect(s.score).to eq(1)
      expect(s.flags).to eq(1)
    end
  end

  it "has a limit on the reason field" do
    s = create(:story)
    u = create(:user)
    v = build(:vote, user: u, story: s, reason: "ABC")

    v.valid?
    expect(v.errors[:reason]).to eq(["is the wrong length (should be 1 character)"])
  end

  it "applies a story upvote and karma properly" do
    s = create(:story)
    expect(s.score).to eq(1)
    expect(s.flags).to eq(0)
    expect(s.user.karma).to eq(0)

    u = create(:user)

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)

    s.reload

    expect(s.score).to eq(2)
    expect(s.user.karma).to eq(1)
  end

  it "does nothing when upvoting an existing upvote" do
    s = create(:story)

    u = create(:user)

    2.times do
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)

      s.reload

      expect(s.score).to eq(2)
      expect(s.user.karma).to eq(1)
    end
  end

  it "has no effect on a story score when casting a hide vote" do
    s = create(:story)
    expect(s.score).to eq(1)

    u = create(:user)

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id, nil, u.id, "H")
    s.reload
    expect(s.user.karma).to eq(0)
    expect(s.score).to eq(1)
    expect(s.flags).to eq(0)
  end

  it "removes upvote when downvoting an upvote" do
    s = create(:story)
    c = create(:comment, story: s)
    expect(c.user.karma).to eq(0)

    u = create(:user)

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, c.id, u.id, nil)
    c.reload
    expect(c.user.karma).to eq(1)
    # initial poster upvote plus new user's vote
    expect(c.score).to eq(2)
    expect(c.flags).to eq(0)

    # flip vote
    Vote.vote_thusly_on_story_or_comment_for_user_because(
      -1, s.id, c.id, u.id, Vote::COMMENT_REASONS.keys.first
    )
    c.reload

    expect(c.user.karma).to eq(0) # doesn't change bc flags don't affect score
    expect(c.score).to eq(0)
    expect(c.flags).to eq(1)
  end

  it "neutralizes karma and upvote when unvoting an upvote" do
    s = create(:story)
    c = create(:comment, story_id: s.id)
    u = create(:user)
    expect(c.user.karma).to eq(0)

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, c.id, u.id, nil)
    c.reload
    expect(c.user.karma).to eq(1)
    expect(c.score).to eq(2)
    expect(c.flags).to eq(0)

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id, c.id, u.id, nil)
    c.reload

    expect(c.user.karma).to eq(0)
    expect(c.score).to eq(1)
    expect(c.flags).to eq(0)
  end
end
