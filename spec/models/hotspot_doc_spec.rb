require "rails_helper"

describe HotspotDoc do
  def moderated(text) = create(:comment, comment: text, is_deleted: true, is_moderated: true)

  describe ".sync!" do
    it "adds moderated comments to the bad set" do
      bad = moderated("monad")
      expect(HotspotDoc.sync!(bad)).to be true
      expect(HotspotTermCount.find_by(term: "monad").bad_doc_count).to eq(1)
      expect(HotspotDoc.sync!(bad)).to be false
    end

    it "updates terms when a bad doc is edited" do
      bad = moderated("monad")
      HotspotDoc.sync!(bad)

      bad.update!(comment: "functor")
      expect(HotspotDoc.sync!(bad)).to be true
      expect(HotspotDoc.find_by(comment: bad).terms).to eq(["functor"])
      expect(HotspotTermCount.pluck(:term)).to eq(["functor"])
    end

    it "keeps recent good comments without counting their terms" do
      good = create(:comment, comment: "functor")
      expect(HotspotDoc.sync!(good)).to be false
      expect(HotspotDoc.find_by(comment: good).terms).to eq(["functor"])
      expect(HotspotTermCount.count).to eq(0)
    end
  end

  describe ".expire!" do
    it "ages out not-bad comment docs" do
      good = create(:comment, comment: "functor")
      bad = moderated("monad")
      [good, bad].each { HotspotDoc.sync!(it) }

      [good, bad].each { it.update_column(:created_at, 10.years.ago) }
      HotspotDoc.expire!
      expect(HotspotDoc.pluck(:comment_id)).to eq([bad.id])
      expect(HotspotTermCount.pluck(:term)).to eq(["monad"])
    end
  end

  describe "scoring" do
    before do
      stub_const("HotspotTerm::MIN_BAD_DOCS", 1)
      stub_const("HotspotTerm::CONFIDENCE_Z", 0.0)
    end

    it "rescores existing docs when weights change" do
      # a comment's doc starts out at a logit of zero
      comment = create(:comment, comment: "a monad is like a burrito")
      HotspotIndexJob.perform_now(comment)
      doc = HotspotDoc.find_by(comment:)
      expect(doc.logit).to eq(0.0)

      # create good docs without "monad" and a bad one with it
      create_list(:comment, 3)
      bad = moderated("monad")
      HotspotIndexJob.perform_now(bad)

      # only "monad" becomes a bad term, and it increases logit of the other comment
      doc.reload
      expect(HotspotTerm.pluck(:term)).to eq(["monad"])
      expect(doc.matched_terms.keys).to eq(["monad"])
      expect(doc.logit > 0.0)
    end
  end
end
