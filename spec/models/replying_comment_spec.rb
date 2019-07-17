require "rails_helper"

RSpec::Matchers.define :have_reply do |expected|
  match do |actual|
    ReplyingComment.for_user(actual.user).map(&:comment).include? expected
  end

  failure_message do |actual|
    "expected that comment #{actual.id} would be in " \
      "#{ReplyingComment.for_user(expected.user).map(&:comment_id)}"
  end
end

describe ReplyingComment do
  def followed_parent
    p = create(:comment)
    ReadRibbon.create(user_id: p.user_id, story_id: p.story_id, updated_at: p.created_at - 1.second)
    p
  end

  def reply_to(p)
    create(:comment, story_id: p.story_id, parent_comment: p)
  end

  def flag_comment(comment, by = create(:user))
    Vote.vote_thusly_on_story_or_comment_for_user_because(
      -1, comment.story_id, comment.id, by.id, 'T'
    )
  end

  describe "is listed when" do
    it "it's a direct reply" do
      p = followed_parent
      r = reply_to p

      expect(p).to have_reply(r)
    end
  end

  describe "is not listed when" do
    it "parent has a negative score" do
      p = followed_parent
      flag_comment(p)
      flag_comment(p)
      r = reply_to p

      expect(p).to_not have_reply(r)
    end

    it "it has a negative score" do
      p = followed_parent
      r = reply_to p
      flag_comment(r)
      flag_comment(r)

      expect(p).to_not have_reply(r)
    end

    it "parent is deleted" do
      p = followed_parent
      r = reply_to p
      p.delete_for_user(p.user)

      expect(p).to_not have_reply(r)
    end

    it "it is deleted" do
      p = followed_parent
      r = reply_to p
      r.delete_for_user(r.user)

      expect(p).to_not have_reply(r)
    end

    it "parent is moderated" do
      p = followed_parent
      r = reply_to p
      p.delete_for_user(create(:user, :admin), "obvs because I disagree with your politics")

      expect(p).to_not have_reply(r)
    end

    it "it is moderated" do
      p = followed_parent
      r = reply_to p
      r.delete_for_user(create(:user, :admin), "obvs because I disagree with your politics")

      expect(p).to_not have_reply(r)
    end

    it "it is on a story with a negative score" do
      p = followed_parent
      r = reply_to p
      Vote.vote_thusly_on_story_or_comment_for_user_because(
        -1, p.story_id, nil, create(:user).id, 'O'
      )
      Vote.vote_thusly_on_story_or_comment_for_user_because(
        -1, p.story_id, nil, create(:user).id, 'O'
      )

      expect(p.story.reload.score).to be < 0
      expect(p).to_not have_reply(r)
    end

    it "commenter has not flagged child commenter in the story" do
      p = followed_parent
      r = reply_to p

      expect(p).to have_reply(r)

      flag_comment(r, p.user)
      expect(p).to_not have_reply(r)
    end
  end
end
