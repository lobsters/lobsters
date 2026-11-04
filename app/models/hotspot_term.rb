class HotspotTerm < ApplicationRecord
  TOP_TERMS = 300
  MIN_BAD_DOCS = 5
  CONFIDENCE_Z = 2.0 # weights are this many standard errors below the log-odds
  SMOOTHING = 0.5

  validates :term, presence: true
  validates :weight, numericality: true

  # {term => weight}, the model HotspotDoc#rescore applies
  def self.weights
    pluck(:term, :weight).to_h
  end

  # remember to run HotspotRefreshJob(from_scratch: true) after algo changes
  def self.refresh!
    bad_total = HotspotDoc.where(bad: true).count
    good_total = Comment.count - bad_total
    candidates = HotspotTermCount.where(bad_doc_count: MIN_BAD_DOCS..).pluck(:term, :bad_doc_count)
    doc_freq = all_doc_frequencies(candidates.map(&:first))

    # naive bayes search for bad terms, similar to https://paulgraham.com/spam.html
    rows = candidates.filter_map { |term, bad|
      next unless (df = doc_freq[term])
      # comments_fts keeps deleted comments, so df includes the bad docs
      log_odds, std_err = log_odds(bad, bad_total, [df - bad, 0].max, good_total)
      weight = log_odds - CONFIDENCE_Z * std_err
      # after all that, more weight = more bad
      {term: term, weight: weight} if weight.positive?
    }.max_by(TOP_TERMS) { |r| r[:weight] }

    ActiveRecord::Base.transaction do
      delete_all
      insert_all(rows) if rows.any?
    end
    HotspotDoc.recalculate_all!
  end

  # Weight terms by how much more often they appear in known-bad comments than in all other comments.
  #
  # We calculate the log_odds ratio of the term appearing in a bad vs. a good doc and its std_err.
  # This is the "Woolf method"/"logit", which produces decent results without being unfathomably
  # complicated. My very limited stats knowledge means there's almost certainly something terribly
  # wrong in approach or this implementation but the results on prod data are more than good enough.
  #
  # confidence interval methods: https://www.researchgate.net/profile/Raef-Lawson/publication/243044499_Small_Sample_Confidence_Intervals_for_the_Odds_Ratio/links/59de3a69aca27247d7942837/Small-Sample-Confidence-Intervals-for-the-Odds-Ratio.pdf
  def self.log_odds(bad, bad_total, good, good_total)
    a = SMOOTHING # "Haldane-Anscombe correction" and https://en.wikipedia.org/wiki/Additive_smoothing
    # equation 16 and 19: https://languagelog.ldc.upenn.edu/myl/Monroe.pdf#page=14
    log_odds = Math.log((bad + a) / (bad_total - bad + a)) - Math.log((good + a) / (good_total - good + a))
    variance = 1 / (bad + a) + 1 / (bad_total - bad + a) + 1 / (good + a) + 1 / (good_total - good + a)
    [log_odds, Math.sqrt(variance)]
  end

  # {term: number of comments containing it} extracted from comments_fts
  def self.all_doc_frequencies(terms)
    conn = ActiveRecord::Base.connection
    conn.execute("create virtual table if not exists temp.comments_fts_vocab using fts5vocab(main, comments_fts, row)")
    terms.each_slice(500).flat_map { |slice|
      conn.select_rows(ActiveRecord::Base.sanitize_sql_array(
        ["select term, doc from temp.comments_fts_vocab where term in (?)", slice]
      ))
    }.to_h
  end
end
