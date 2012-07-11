class SearchController < ApplicationController
  def index
    @title = "Search"
    @cur_url = "/search"

    @search = Search.new

    if params[:q].present?
      @search.q = params[:q]
      @search.what = params[:what]
      @search.order = params[:order]

      if params[:page]
        @search.page = params[:page].to_i
      end

      if @search.valid?
        @search.search_for_user!(@user)
      end
    end

    render :action => "index"
  end
end
