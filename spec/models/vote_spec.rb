require "spec_helper"

describe Vote do
  it "applies a story upvote and karma properly" do
    s = Story.make!

    s.upvotes.should == 1
    s.downvotes.should == 0
    s.user.karma.should == 0

    u = User.make!

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id,
      nil, u.id, nil)

    s.reload

    s.upvotes.should == 2
    s.user.karma.should == 1
  end

  it "does nothing when upvoting an existing upvote" do
    s = Story.make!

    u = User.make!

    2.times do
      Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id,
        nil, u.id, nil)

      s.reload

      s.upvotes.should == 2
      s.user.karma.should == 1
    end
  end

  it "has no effect on a story score when casting a hide vote" do
    s = Story.make!
    s.upvotes.should == 1

    u = User.make!

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id,
      nil, u.id, "H")
    s.reload
    s.user.karma.should == 0
    s.upvotes.should == 1
    s.downvotes.should == 0
  end

  it "removes karma and upvote when downvoting an upvote" do
    s = Story.make!
    c = Comment.make!(:story_id => s.id)
    c.user.karma.should == 0

    u = User.make!

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id,
      c.id, u.id, nil)
    c.reload
    c.user.karma.should == 1
    # initial poster upvote plus new user's vote
    c.upvotes.should == 2
    c.downvotes.should == 0

    # flip vote
    Vote.vote_thusly_on_story_or_comment_for_user_because(-1, s.id,
      c.id, u.id, Vote::COMMENT_REASONS.keys.first)
    c.reload

    c.user.karma.should == -1
    c.upvotes.should == 1
    c.downvotes.should == 1
  end

  it "neutralizes karma and upvote when unvoting an upvote" do
    s = Story.make!
    c = Comment.make!(:story_id => s.id)

    u = User.make!

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, s.id,
      c.id, u.id, nil)
    c.reload
    c.user.karma.should == 1
    c.upvotes.should == 2
    c.downvotes.should == 0

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, s.id,
      c.id, u.id, nil)
    c.reload

    c.user.karma.should == 0
    c.upvotes.should == 1
    c.downvotes.should == 0
  end
end
