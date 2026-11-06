# This controller is going to have a lot of one-off queries. If they do need
# to be used elsewhere, remember to make them into model scopes.

class Mod::FlaggedController < Mod::ModController
  include IntervalHelper

  def flagged_stories
    @title = "Flagged Stories"
    @stories = period(Story.base(@user).unmerged
      .includes(:user, :tags)
      .where("flags > 1")
      .order("stories.id DESC"))
  end

  def flagged_comments
    @title = "Flagged Comments"
    @comments = CommentVoteHydrator.new(period(Comment
      .eager_load(:user, :hat, story: :user, votes: :user)
      .mod_flagged
      .order("comments.id DESC")).to_a, @user)
  end

  def commenters
    @title = "Flagged Commenters"
    fc = FlaggedCommenters.new(params[:period])
    @interval = fc.interval
    @agg = fc.aggregates
    @commenters = fc.commenters
  end
end
