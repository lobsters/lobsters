# This controller is going to have a lot of one-off queries. If they do need
# to be used elsewhere, remember to make them into model scopes.

class ModController < ApplicationController
  include IntervalHelper

  before_action :require_logged_in_moderator, :default_periods

  def index
    @title = "Mod Activity"
    @moderations = Moderation.all
      .eager_load(:moderator, :story, :tag, :user, :comment => [:story, :user])
      .where("moderator_user_id != ? or moderator_user_id is null", @user.id)
      .where('moderations.created_at >= (NOW() - INTERVAL 1 MONTH)')
      .order('moderations.id desc')
  end

  def flagged
    @title = "Flagged Stories"
    @stories = period(Story.includes(:tags).unmerged
      .includes(:user, :tags)
      .where("downvotes > 1")
      .order("stories.id DESC"))
  end

  def downvoted
    @title = "Downvoted Comments"
    @comments = period(Comment
      .eager_load(:user, :hat, :story => :user, :votes => :user)
      .where("(select count(*) from votes where
                votes.comment_id = comments.id and
                vote < 0 and
                votes.reason != 'M') > 2") # Me-Too comments rarely need attention
      .order("comments.id DESC"))
  end

  def commenters
    @title = "Downvoted Commenters"
    dvc = DownvotedCommenters.new(params[:period])
    @interval = dvc.interval
    @agg = dvc.aggregates
    @commenters = dvc.commenters
  end

private

  def default_periods
    @periods = %w{1d 2d 3d 1w 1m}
  end

  def period(query)
    length = time_interval(params[:period] || default_periods.first)
    query.where("#{query.model.table_name}.created_at >=
      (NOW() - INTERVAL #{length[:dur]} #{length[:intv].upcase})")
  end
end
