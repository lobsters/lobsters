# typed: false

class SearchController < ApplicationController
  before_action :show_title_h1

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

  def search_params
    params.permit(:q, :what, :order, :page, :utf8, :authenticity_token)
  end
end
