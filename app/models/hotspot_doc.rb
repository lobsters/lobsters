# These aren't just fields on Comment because to avoid widening the god object with mod-only data,
# and we can delete unactioned docs after a month.
class HotspotDoc < ApplicationRecord
  BATCH_SIZE = 1_000 # don't take a long write lock
  RECENT = 32.days

  belongs_to :comment

  after_destroy { HotspotTermCount.remove!(terms) if bad }

  validates :comment_id, uniqueness: true
  # not presence: empty is valid
  validates :terms, :matched_terms, exclusion: {in: [nil], message: :blank}
  validates :token_count, numericality: {only_integer: true}
  validates :bad, inclusion: {in: [true, false]}
  validates :logit, numericality: true

  # delete docs for old non-bad comments
  def self.expire!
    where(bad: false)
      .joins(:comment)
      .where(comments: {created_at: ...RECENT.ago})
      .in_batches(of: BATCH_SIZE)
      .delete_all
    # non-bad comments don't add to HotspotTermCounts, nothing to do there
  end

  # toss everything and rebuild from scratch
  def self.rebuild!
    in_batches(of: BATCH_SIZE).delete_all
    HotspotTermCount.in_batches(of: BATCH_SIZE).delete_all

    bad_ids = Comment.hotspot_bad_and_naughty.pluck(:id).to_set
    reindex_ids = bad_ids | Comment.where(created_at: RECENT.ago..).pluck(:id).to_set
    weights = HotspotTerm.weights
    reindex_ids.each_slice(BATCH_SIZE) { |slice|
      docs = build_all(Comment.where(id: slice), bad_ids, weights)
      insert_all(docs.map(&:row))
      HotspotTermCount.add!(docs.select(&:bad).flat_map(&:terms))
    }
  end

  # recalculate the logit of docs for new weights
  def self.recalculate_all!
    weights = HotspotTerm.weights
    in_batches(of: BATCH_SIZE) do |batch|
      docs = batch.each { |doc| doc.recalculate(weights) }
      upsert_all(docs.map(&:row), unique_by: :comment_id, update_only: [:logit, :matched_terms])
    end
  end

  def self.build_all(comments, bad_ids, weights)
    now = Time.current
    Comment.tokenize(comments).map { |t|
      new(comment: t.comment,
        terms: t.terms,
        token_count: t.count,
        bad: bad_ids.include?(t.comment.id),
        created_at: now).recalculate(weights)
    }
  end

  # Idempotently tokenize and score added/edited comments, delete old good comments.
  # Returns whether comment entered or left the bad set, indicating HotspotTerm.refresh! is needed.
  def self.sync!(comment)
    old = find_by(comment_id: comment.id)
    was_bad = old&.bad || false
    is_bad = Comment.hotspot_bad_and_naughty.exists?(comment.id)

    # comment aged out without becoming bad, no need to track it anymore
    if !is_bad && comment.created_at < RECENT.ago
      old&.destroy
      return was_bad
    end

    doc = build_all([comment], is_bad ? [comment.id] : [], HotspotTerm.weights).first
    bad_set_changed = was_bad != is_bad || (is_bad && old.terms != doc.terms)
    HotspotTermCount.remove!(old.terms) if bad_set_changed && was_bad
    HotspotTermCount.add!(doc.terms) if bad_set_changed && is_bad
    upsert(doc.row, unique_by: :comment_id)
    bad_set_changed
  end

  # logit s the sum of weights of matched terms divided by sqrt(n terms) to normalize by length
  def recalculate(weights)
    contributions = weights.slice(*terms).transform_values { |w| w / Math.sqrt(token_count) }
    self.matched_terms = contributions.sort_by { |_, c| -c }.to_h
    self.logit = matched_terms.values.sum(0.0)
    self
  end

  # attributes for insert_all/upsert_all, which don't take model instances
  def row
    attributes.except("id")
  end
end
