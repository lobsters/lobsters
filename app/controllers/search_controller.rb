# typed: false

class SearchController < ApplicationController
  before_action :show_title_h1
  before_action :ignore_searx

  def index
    @title = "Search"

    @search = Search.new(search_params, @user)

    if !@user && params[:q].to_s.starts_with?("https://")
      flash[:error] = "Sorry, you have to log in to search for a URL. We're getting hammered by a spambot with many thousands of IPs. More info at https://github.com/lobsters/lobsters/issues/1814"
      @results = []
    else
      @results = @search.results
    end

    if @user && @search.results
      if params[:what] == "stories"
        votes = Vote.story_votes_by_user_for_story_ids_hash(@user.id, @search.results.map(&:id))
        @search.results.each do |r|
          r.current_vote = votes.try(:[], r.id)
        end
      end
      @results = if params[:what] == "comments"
        CommentVoteHydrator.new(@search.results, @user)
      else
        @search.results
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
    @results = []
    render :index
  end

  def search_params
    params.permit(:q, :what, :order, :page, :authenticity_token)
  end
end
