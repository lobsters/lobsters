describe StoryRepository do
  let(:current_user) { nil }
  let(:stories)      { described_class.new current_user }

  describe '#hottest' do
    subject { stories.hottest }

    it 'excludes merged stories' do
      merged = Story.make! merged_story_id: 10
      expect(subject).not_to include merged
    end

    it 'excludes expired stories' do
      expired = Story.make! is_expired: true
      expect(subject).not_to include expired
    end

    it 'excludes stories with filtered tags' do
      filtered_tag = Tag.create! tag: 'not_interesting_stuff'
      story = Story.make!
      tagged_story = Story.make!
      tagged_story.taggings.create! tag: filtered_tag

      hottest = described_class.new(current_user, exclude_tags: [filtered_tag.id]).hottest

      expect(hottest).to include story
      expect(hottest).not_to include tagged_story
    end

    it 'includes story with 3 downvote and 1 upvotes' do
      story = Story.make! downvotes: 3
      expect(subject).to include story
    end

    it 'excludes story with 4 downvotes and 1 upvotes' do
      story = Story.make! downvotes: 4
      expect(subject).not_to include story
    end

    it 'orders by hotness asc' do
      meh = Story.make! hotness: 50
      hot = Story.make! hotness: 100
      cool = Story.make! hotness: 25

      expect(subject).to eq [cool, meh, hot]
    end

    context 'logged in' do
      let(:current_user) { User.make! }

      it 'excludes downvoted stories' do
        downvoted = Story.make!
        Vote.create! story: downvoted, user: current_user, vote: -1
        expect(subject).not_to include downvoted
      end
    end
  end

  describe '#hidden' do
    subject { stories.hidden }

    context 'logged in' do
      let(:current_user) { User.make! }

      it 'includes downvoted story' do
        downvoted = Story.make!
        Vote.create! story: downvoted, user: current_user, vote: -1
        expect(subject).to include downvoted
      end

      it 'excludes visible story' do
        visible = Story.make!
        expect(subject).not_to include visible
      end
    end
  end

  describe '#newest' do
    subject { stories.newest }

    it 'orders by created_at' do
      story1 = Story.make! created_at: 1.hour.ago
      story2 = Story.make! created_at: 5.hours.ago
      story3 = Story.make! created_at: 5.minutes.ago

      expect(subject).to eq [story3, story1, story2]
    end
  end

  describe '#newest_by_user' do
    let(:another_user) { User.make! }

    subject { stories.newest_by_user(another_user) }

    it 'orders by id descending' do
      story1 = Story.make! user_id: another_user.id
      story2 = Story.make!
      story3 = Story.make! user_id: another_user.id

      expect(subject).to eq [story3, story1]
    end
  end

  describe '#recent' do
    subject { stories.recent }

    it 'orders by created_at' do
      story1 = Story.make! created_at: 1.hour.ago
      story2 = Story.make! created_at: 5.hours.ago
      story3 = Story.make! created_at: 5.minutes.ago

      expect(subject).to eq [story3, story1, story2]
    end
  end

  describe '#tagged' do
    let(:tag) { Tag.make! }
    let(:tagged) do
      story = Story.make!
      story.taggings.create! tag: tag
      story
    end

    subject { stories.tagged(tag) }

    it 'excludes stories not tagged' do
      story = Story.make!
      expect(subject).not_to include story
    end

    it 'includes stories tagged' do
      expect(subject).to include tagged
    end

    it 'includes story with 3 downvote and 1 upvotes' do
      tagged.update_attribute :downvotes, 3
      expect(subject).to include tagged
    end

    it 'excludes story with 4 downvotes and 1 upvotes' do
      tagged.update_attribute :downvotes, 4
      expect(subject).not_to include tagged
    end
  end

  describe '#top' do
    context 'filtering' do
      subject { stories.top(length) }

      let!(:month_ago) { Story.make! created_at: 1.month.ago }
      let!(:ten_month_ago) { Story.make! created_at: 10.month.ago }

      context '2 weeks' do
        let(:length) { { dur: 2, intv: 'Week' } }

        it { should_not include month_ago }
      end

      context '2 month' do
        let(:length) { { dur: 2, intv: 'Month' } }

        it { should include month_ago }
        it { should_not include ten_month_ago }
      end
    end

    context 'ordering' do
      it 'orders by votes difference' do
        scope = stories.top dur: 12, intv: 'Month'

        s1 = Story.make! downvotes: 10
        s2 = Story.make! downvotes: 5
        s3 = Story.make! downvotes: 3
        s4 = Story.make! downvotes: 8

        expect(scope).to eq [s3, s2, s4, s1]
      end
    end
  end
end
