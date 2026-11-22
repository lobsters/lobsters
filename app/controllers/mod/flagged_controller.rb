# This controller is going to have a lot of one-off queries. If they do need
# to be used elsewhere, remember to make them into model scopes.

class Mod::FlaggedController < Mod::ModController
  include IntervalHelper

  def commenters
    @title = "Flagged Commenters"
    fc = FlaggedCommenters.new(params[:period])
    @interval = fc.interval
    @agg = fc.aggregates
    @commenters = fc.commenters
  end
end
