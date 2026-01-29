class RecalculateCommentConfidences < ActiveRecord::Migration[7.1]
  # it's ok to incrementally fix this old data, and we don't want to lock popular tables
  disable_ddl_transaction!

  def change
    # Refresh the memoization of score and flags for all comments.
    # 1. Three comments (lli01e, gairjl, ajbg61) in the db have the wrong memoized score (1, when
    # the author apparently unvoted).
    # 2. Comment.delete_for_user set score to FLAGGABLE_MIN_SCORE; now handled by calculated_confidence
    Comment.all.update_all <<~SQL
      score = (select coalesce(sum(vote), 0) from votes where comment_id = comments.id),
      flags = (select count(*) from votes where comment_id = comments.id and vote = -1)
    SQL

    # now recalc all confidences on all comments
    Comment.all.find_each do |c|
      c.update_score_and_recalculate! 0, 0
    end
  end
end
