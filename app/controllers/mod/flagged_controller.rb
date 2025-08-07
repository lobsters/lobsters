# typed: false

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
    @comments = period(Comment
      .eager_load(:user, :hat, story: :user, votes: :user)
      .where("comments.flags >= 2")
      .where("(select count(*) from votes where
                votes.comment_id = comments.id and
                vote < 0 and
                votes.reason != 'M') > 2") # Me-Too comments rarely need attention
      .order("comments.id DESC"))
  end

  def commenters
    @title = "Flagged Commenters"
    fc = FlaggedCommenters.new(params[:period])
    @interval = fc.interval
    @agg = fc.aggregates
    @commenters = fc.commenters
  end
end
