# typed: false

class SearchController < ApplicationController
  before_action :show_title_h1
  before_action :ignore_searx

  def index
    @title = "Search"

    @search = Search.new(search_params, @user)

    if @user && @search.results
      summaries = {}
      if params[:what] == "stories"
        votes = Vote.story_votes_by_user_for_story_ids_hash(@user.id, @search.results.map(&:id))
      end
      if params[:what] == "comments"
        comment_ids = @search.results.map(&:id)
        votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, comment_ids)
        summaries = Vote.comment_vote_summaries(comment_ids)
      end
      @search.results.each do |r|
        r.current_vote = votes.try(:[], r.id)
        r.vote_summary = summaries[r.id] if params[:what] == "comments"
      end
    end
  end

  private

  # searx is a meta-search engine, instances send endless garbage traffic to our most-expensive
  # endpoint https://github.com/searx/searx/blob/master/searx/settings.yml#L807
  # If you are maintaining a searx fork, please don't 'fix' your targeting of this site.
  def ignore_searx
    return unless params[:utf8] == "✓"
    @search = Search.new({results_count: 0}, nil)
    render :index
  end

  def search_params
    params.permit(:q, :what, :order, :page, :authenticity_token)
  end
end
