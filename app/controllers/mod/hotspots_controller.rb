class Mod::HotspotsController < Mod::ModController
  include IntervalHelper

  def index
    @title = "Hotspots"
    @min_logit = min_logit
    @terms = HotspotTerm.order(weight: :desc).pluck(:term)
    @comments = CommentVoteHydrator.new(period(Comment
      .for_presentation
      .includes(:hotspot_doc)
      .not_moderated
      .where.not(id: Comment.mod_flagged.select(:id))
      .where(id: HotspotDoc.where(logit: @min_logit..).where.not(logit: ..0.0).select(:comment_id))
      .order("comments.id DESC")).to_a, @user)
  end

  private

  def min_logit
    Rails.cache.fetch("hotspot_min_logit", expires_in: 1.hour) do
      logits = HotspotDoc.where(bad: true).where.not(logit: ..0.0).joins(:comment).where(comments: {is_moderated: true})
      n = logits.count
      # show comments down to 25th percentile of mod-deleted comments, with a leeway so mods see
      # comments that aren't obviously over the line
      n.zero? ? 0.0 : logits.order(:logit).offset(n * 0.25).pick(:logit) * 0.75
    end
  end
end
