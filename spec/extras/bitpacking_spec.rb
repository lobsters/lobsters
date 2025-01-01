# typed: false

require "rails_helper"

# Story#merged_comments (and Comment.confidence_order) depend on a lot of fiddly SQL.
# If any of these tests fail, START HERE because these are fundamental assumptions for those
# queries. Hopefully this doesn't even happen if you are migrating to a different db.

def one_result sql
  ActiveRecord::Base.connection.exec_query("SELECT #{sql};").first.first.last
end

RSpec::Matchers.define :be_bytes do |bytes|
  match do |str|
    str.eql?(bytes.b)
  end
end

describe "sql assumptions" do
  describe "char" do
    it "handles zero" do
      expect(one_result("char(0 using binary)")).to be_bytes("\x00")
    end

    it "handles small int" do
      expect(one_result("char(7 using binary)")).to be_bytes("\x07")
    end

    it "handles 2^8-1" do
      expect(one_result("char(255 using binary)")).to be_bytes("\xff")
    end

    it "overflows big-endian" do
      expect(one_result("char(256 using binary)")).to be_bytes("\x01\x00")
      expect(one_result("char(258 using binary)")).to be_bytes("\x01\x02")
    end
  end

  describe "concat" do
    it "can concatenate raw bytes" do
      expect(one_result("concat(char(1 using binary), char(2 using binary))")).to \
        be_bytes("\x01\x02")
      expect(
        one_result("concat(char(1 using binary), char(2 using binary), char(3 using binary))")
      ).to be_bytes("\x01\x02\x03")
    end
  end

  describe "lpad" do
    it "pads null to null" do
      # this is two ways of saying 'pad with nulls'; included to avoid padding with '0' instead of '\0'
      expect(one_result("lpad(null, 2, char(0 using binary))")).to eq(nil)
      expect(one_result("lpad(null, 2, '\0')")).to eq(nil)
    end

    it "pads empty string to two bytes" do
      expect(one_result("lpad('', 2, '\0')")).to be_bytes("\x00\x00")
    end

    it "pads one byte to two" do
      expect(one_result("lpad(char(0 using binary), 2, '\0')")).to \
        be_bytes("\x00\x00")
    end

    it "doesn't change two bytes" do
      expect(one_result("lpad(char(258 using binary), 2, '\0')")).to \
        be_bytes("\x01\x02")
    end

    it "pads on the left, per name" do
      expect(one_result("lpad(char(1 using binary), 2, char(0 using binary))")).to \
        be_bytes("\x00\x01")
    end

    it "truncates on the right" do
      expect(one_result("
        lpad(
          concat(char(1 using binary), char(2 using binary), char(3 using binary)),
          2,
          char(0 using binary)
        )")).to be_bytes("\x01\x02")
    end
  end

  describe "&0xff to mask off lowest byte" do
    it "returns byte" do
      expect(one_result("65 & 0xff")).to eq(65)
    end

    it "returns byte at boundary" do
      expect(one_result("255 & 0xff")).to eq(255)
    end

    it "truncates on overflow" do
      expect(one_result("258 & 0xff")).to eq(2)
    end

    it "truncates on multibyte overflow" do
      # current number of comments
      expect(one_result("435431 & 0xff")).to eq(231)

      # number of bits currently needed for comment IDs
      expect(one_result("#{2**(5 * 8) - 1} & 0xff")).to eq(255)

      # more than the number of bits currently needed for comment IDs
      expect(one_result("#{2**(5 * 9) - 1} & 0xff")).to eq(255)
    end
  end

  # the inner numbers here are extreme but possible highest and lowest possible 'confidence' values
  describe "confidence_order" do
    it "is low for a high-voted comment" do
      expect(one_result("
        lpad(char(65535 - floor(0.98 * 65535) using binary), 2, '\0')
      ").bytes).to eq([5, 31])
    end

    it "is middle for a low-score comment" do
      expect(one_result("
        lpad(char(65535 - floor(0.464 * 65535) using binary), 2, '\0')
        ").bytes).to eq([137, 55])
    end

    it "is high for a heavily flagged comment" do
      expect(one_result("
        lpad(char(65535 - floor(0.05 * 65535) using binary), 2, '\0')
      ").bytes).to eq([243, 51])
    end

    it "is close to ffff for the worst score" do
      expect(one_result("
        lpad(char(65535 - floor(0.00001 * 65535) using binary), 2, '\0')
      ").bytes).to eq([255, 255])
    end
  end

  describe "cast() confidence_order to char for base case of recursive CTE" do
    it "is left-aligned because sql sorts the char column lexiographically" do
      # in the CTE this is char(93) but 6 is more than enough to verify assumption
      expect(one_result("cast(char(0x010203 using binary) as char(6) character set binary)")).to \
        be_bytes("\01\02\03\00\00\00")
    end
  end

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
