# typed: false

class SearchController < ApplicationController
  before_action :show_title_h1
  before_action :ignore_searx

  def index
    @title = "Search"

    @search = Search.new(search_params, @user)

    if @user && @search.results
      if params[:what] == "stories"
        votes = Vote.story_votes_by_user_for_story_ids_hash(@user.id, @search.results.map(&:id))
      end
      if params[:what] == "comments"
        votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, @search.results.map(&:id))
      end
      @search.results.each { |r| r.current_vote = votes.try(:[], r.id) }
    end
  end

  private

  # searx is a meta-search engine, instances send endless garbage traffic to our most-expensive
  # endpoint https://github.com/searx/searx/blob/master/searx/settings.yml#L807
  # If you are maintaining a searx fork, please don't 'fix' your targeting of this site.
  def ignore_searx
    return unless params[:utf8] == "✓"
    @search = Search.new({}, nil)
    render :index
  end

  def search_params
    params.permit(:q, :what, :order, :page, :authenticity_token)
  end
end
