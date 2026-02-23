# typed: false

require "rails_helper"

describe "sql assumptions" do
  describe "Comment#update_score_and_recalculate matches SQL math" do
    it "initializes correctly" do
      c = create(:comment, id: 9, score: 1, flags: 0)
      c.reload
      expect(c.confidence_order.bytes).to eq([159, 30, c.id])
    end

    it "increments correctly" do
      c = create(:comment, id: 4, score: 1, flags: 0)
      expect(c.confidence_order.bytes).to eq([0, 0, 0]) # placeholder on creation
      create(:vote, story: c.story, comment: c)
      c.update_score_and_recalculate!(1, 0)
      c.reload
      expect(c.confidence_order.bytes.last).to eq(c.id) # id included after vote
    end
  end
end
