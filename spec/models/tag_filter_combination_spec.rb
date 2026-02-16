# typed: false

require "rails_helper"

RSpec.describe TagFilterCombination, type: :model do
  let(:user) { create(:user) }
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }
  let(:tag3) { create(:tag) }

  describe "validations" do
    it "requires at least 2 tags" do
      combo = user.tag_filter_combinations.build
      combo.tags = [tag1]
      expect(combo).not_to be_valid
      expect(combo.errors[:tags]).to include("must have at least 2 tags")
    end

    it "allows 2 tags" do
      combo = user.tag_filter_combinations.build
      combo.tags = [tag1, tag2]
      expect(combo).to be_valid
    end

    it "allows up to 15 tags" do
      tags = (1..15).map { create(:tag) }
      combo = user.tag_filter_combinations.build
      combo.tags = tags
      expect(combo).to be_valid
    end

    it "rejects more than 15 tags" do
      tags = (1..16).map { create(:tag) }
      combo = user.tag_filter_combinations.build
      combo.tags = tags
      expect(combo).not_to be_valid
      expect(combo.errors[:tags]).to include("must have at most 15 tags")
    end

    it "requires a user" do
      combo = TagFilterCombination.new
      combo.tags = [tag1, tag2]
      expect(combo).not_to be_valid
      expect(combo.errors[:user_id]).to be_present
    end
  end

  describe "callbacks" do
    it "computes combo_hash before validation" do
      combo = user.tag_filter_combinations.build
      combo.tags = [tag1, tag2]
      combo.valid?
      expect(combo.combo_hash).to be > 0
      expect(combo.combo_hash).to eq((1 << (tag1.id % 64)) | (1 << (tag2.id % 64)))
    end

    it "computes tag_count before validation" do
      combo = user.tag_filter_combinations.build
      combo.tags = [tag1, tag2, tag3]
      combo.valid?
      expect(combo.tag_count).to eq(3)
    end
  end

  describe "associations" do
    it "belongs to user" do
      combo = user.tag_filter_combinations.create!(tags: [tag1, tag2])
      expect(combo.user).to eq(user)
    end

    it "has many tags through tag_filter_combination_tags" do
      combo = user.tag_filter_combinations.create!(tags: [tag1, tag2, tag3])
      expect(combo.tags).to contain_exactly(tag1, tag2, tag3)
    end

    it "destroys join records when destroyed" do
      combo = user.tag_filter_combinations.create!(tags: [tag1, tag2])
      expect { combo.destroy }.to change { TagFilterCombinationTag.count }.by(-2)
    end
  end

  describe "bloom filter computation" do
    it "creates consistent bloom filter for same tags" do
      combo1 = user.tag_filter_combinations.create!(tags: [tag1, tag2])
      combo2 = user.tag_filter_combinations.create!(tags: [tag1, tag2])
      expect(combo1.combo_hash).to eq(combo2.combo_hash)
    end

    it "creates same hash regardless of tag order" do
      user2 = create(:user)
      combo1 = user.tag_filter_combinations.create!(tags: [tag1, tag2, tag3])
      combo2 = user2.tag_filter_combinations.create!(tags: [tag3, tag1, tag2])
      expect(combo1.combo_hash).to eq(combo2.combo_hash)
    end

  end

  describe "per-user limits" do
    it "allows exactly 15 combinations" do
      tags_array = (1..30).map { create(:tag) }

      15.times do |i|
        combo = user.tag_filter_combinations.create!(tags: [tags_array[i * 2], tags_array[i * 2 + 1]])
        expect(combo).to be_valid
      end

      expect(user.tag_filter_combinations.count).to eq(15)
    end

    it "prevents user from having more than 15 combinations" do
      # Create 15 combinations
      tags_array = (1..32).map { create(:tag) }

      15.times do |i|
        user.tag_filter_combinations.create!(tags: [tags_array[i * 2], tags_array[i * 2 + 1]])
      end

      # Try to create 16th combination
      combo = user.tag_filter_combinations.build(tags: [tags_array[30], tags_array[31]])
      expect(combo).not_to be_valid
      expect(combo.errors[:base]).to include("cannot have more than 15 tag filter combinations")
    end
  end
end
