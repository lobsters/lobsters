require "rails_helper"

describe Vote do
  it "applies a story upvote and karma properly" do
    s = create(:story)
    expect(s.upvotes).to eq(1)
    expect(s.downvotes).to eq(0)
    expect(s.user.karma).to eq(0)

    u = create(:user)

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)

    s.reload

    expect(s.upvotes).to eq(2)
    expect(s.user.karma).to eq(1)
  end

  it "does nothing when upvoting an existing upvote" do
    s = create(:story)

    u = create(:user)

    2.times do
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, nil, u.id, nil)

      s.reload

      expect(s.upvotes).to eq(2)
      expect(s.user.karma).to eq(1)
    end
  end

  it "has no effect on a story score when casting a hide vote" do
    s = create(:story)
    expect(s.upvotes).to eq(1)

    u = create(:user)

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id, nil, u.id, "H")
    s.reload
    expect(s.user.karma).to eq(0)
    expect(s.upvotes).to eq(1)
    expect(s.downvotes).to eq(0)
  end

  it "removes karma and upvote when downvoting an upvote" do
    s = create(:story)
    c = create(:comment, :story => s)
    expect(c.user.karma).to eq(0)

    u = create(:user)

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, c.id, u.id, nil)
    c.reload
    expect(c.user.karma).to eq(1)
    # initial poster upvote plus new user's vote
    expect(c.upvotes).to eq(2)
    expect(c.downvotes).to eq(0)

    # flip vote
    Vote.vote_thusly_on_story_or_comment_for_user_because(
      -1, s.id, c.id, u.id, Vote::COMMENT_REASONS.keys.first
    )
    c.reload

    expect(c.user.karma).to eq(-1)
    expect(c.upvotes).to eq(1)
    expect(c.downvotes).to eq(1)
  end

  it "neutralizes karma and upvote when unvoting an upvote" do
    s = create(:story)
    c = create(:comment, :story_id => s.id)

    u = create(:user)

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id, c.id, u.id, nil)
    c.reload
    expect(c.user.karma).to eq(1)
    expect(c.upvotes).to eq(2)
    expect(c.downvotes).to eq(0)

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id, c.id, u.id, nil)
    c.reload

    expect(c.user.karma).to eq(0)
    expect(c.upvotes).to eq(1)
    expect(c.downvotes).to eq(0)
  end
end
