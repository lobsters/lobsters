class HotspotTermCount < ApplicationRecord
  validates :term, presence: true, uniqueness: true
  validates :bad_doc_count, numericality: {only_integer: true}

  def self.add!(terms)
    reconcile!(terms.tally)
  end

  def self.remove!(terms)
    reconcile!(terms.tally.transform_values(&:-@))
    where(bad_doc_count: ..0).delete_all
  end

  # {term => change in bad_doc_count}
  def self.reconcile!(deltas)
    return if deltas.empty?
    upsert_all(
      deltas.map { |term, n| {term: term, bad_doc_count: n} },
      unique_by: :term,
      on_duplicate: Arel.sql("bad_doc_count = bad_doc_count + excluded.bad_doc_count"),
      record_timestamps: false
    )
  end
  private_class_method :reconcile!
end
