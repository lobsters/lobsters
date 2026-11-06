require "rails_helper"

describe ReadRibbon do
  describe "#unread_counts" do
    let(:user) { create(:user) }
    let(:story) { create(:story) }
    let(:merged) { create(:story, merged_into_story: story) }
    let(:ribbon) { ReadRibbon.create!(user:, story:).tap { it.update_column(:updated_at, 1.hour.ago) } }

    it "counts newer comments by other users for each story" do
      create(:comment, story:, created_at: 2.hours.ago)
      create(:comment, story:, user:)
      create(:comment, story:)
      create_list(:comment, 2, story: merged)

      expect(ribbon.unread_counts([story, merged])).to eq(story.id => 1, merged.id => 2)
    end

    it "defaults to 0" do
      expect(ribbon.unread_counts([story])[story.id]).to eq(0)
    end

    it "is 0 for a new ribbon" do
      create(:comment, story:)
      expect(ReadRibbon.new(user:, story:).unread_counts([story])[story.id]).to eq(0)
    end
  end
end
