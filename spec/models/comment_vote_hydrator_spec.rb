require "rails_helper"

describe CommentVoteHydrator do
  let(:user) { create(:user) }
  let(:story) { create(:story) }
  let!(:upvoted) { create(:comment, story:) }
  let!(:flagged) { create(:comment, story:) }
  let(:hydrator) { CommentVoteHydrator.new(Comment.where(id: [upvoted.id, flagged.id]).order(:id).load, user) }

  before do
    Vote.vote_thusly_on_story_or_comment_for_user_because(1, story.id, upvoted.id, user.id, nil)
    Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id, flagged.id, user.id, "T")
  end

  it "hydrates comments when iterating" do
    expect(hydrator.map { [it.current_upvoted?, it.current_flagged?] }).to eq([[true, false], [false, true]])
  end

  it "raises if looped again" do
    hydrator.each {}
    expect { hydrator.each {} }.to raise_error(CommentsLoopedMultipleTimes)
  end

  it "hydrates one comment" do
    expect(hydrator.hydrate(flagged)).to equal(flagged)
    expect(flagged.current_flagged?).to be true
  end

  it "gives random access to hydrated comments by index" do
    comment = hydrator[1]
    expect(comment).to eq(flagged)
    expect(comment.current_flagged?).to be true
    expect(hydrator[-1]).to eq(flagged)
    expect(hydrator[2]).to be_nil
  end

  it "has a StoryThreadWindow onto a range of indexes" do
    thread = CommentVoteHydrator::StoryThreadWindow.new(%w[a b c d e], 1, 3)
    expect(thread.size).to eq(3)
    expect(thread.to_a).to eq(%w[b c d])
    expect(thread[0]).to eq("b")
    expect(thread[-1]).to eq("d")
    expect(thread[3]).to be_nil
    expect(thread[-4]).to be_nil
  end

  describe "#each_thread" do
    let(:merged) { create(:story, merged_into_story: story) }
    let!(:merged_comment) { create(:comment, story: merged) }
    let(:stories) { [story, merged] }
    let(:comments) { Comment.story_threads(stories).load }
    let(:hydrator) { CommentVoteHydrator.new(comments, user) }

    def collect_threads(hydrator = self.hydrator, stories = self.stories)
      result = {}
      hydrator.each_thread(stories) { |story, thread| result[story] = [thread.size, thread.to_a] }
      result
    end

    it "yields each story with its window of comments" do
      threads = collect_threads
      expect(threads.keys).to eq(stories)
      expect(threads[story]).to match([2, contain_exactly(upvoted, flagged)])
      expect(threads[story][1].find { it == upvoted }.current_upvoted?).to be true
      expect(threads[merged]).to eq([1, [merged_comment]])
    end

    it "counts as the one loop" do
      hydrator.each_thread(stories) {}
      expect { hydrator.each {} }.to raise_error(CommentsLoopedMultipleTimes)
    end

    it "gives random access within a thread" do
      hydrator.each_thread(stories) do |s, thread|
        next unless s == merged
        expect(thread[0]).to eq(merged_comment)
        expect(thread[-1]).to eq(merged_comment)
        expect(thread.first).to eq(merged_comment)
        expect(thread[1]).to be_nil
        expect(thread[-2]).to be_nil
      end
    end

    it "skips the comments of a thread the block doesn't loop" do
      seen = []
      hydrator.each_thread(stories) { |s, thread| seen.concat(thread.to_a) if s == merged }
      expect(seen).to eq([merged_comment])
    end

    it "yields an empty thread for a story without comments" do
      empty = create(:story)
      stories.insert(1, empty)
      expect(collect_threads.transform_values(&:first)).to eq(story => 2, empty => 0, merged => 1)
    end

    it "also raises on a repeated loops" do
      hydrator.each_thread([story, merged]) do |s, thread|
        next unless s == story
        thread.each {}
        expect { thread.each {} }.to raise_error(CommentsLoopedMultipleTimes)
      end
    end

    it "raises when comments aren't in order" do
      expect { CommentVoteHydrator.new(comments, user).each_thread(stories.reverse) {} }.to raise_error(ArgumentError)
      expect { CommentVoteHydrator.new(comments, user).each_thread([story]) {} }.to raise_error(ArgumentError)
    end

    it "works without a user" do
      expect(collect_threads(CommentVoteHydrator.new(comments, nil))[merged]).to eq([1, [merged_comment]])
    end
  end
end
