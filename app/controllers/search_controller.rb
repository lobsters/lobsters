class SearchController < ApplicationController
  def index
    @title = "Search"
    @cur_url = "/search"

    @search = Search.new

    if params[:q].to_s.present?
      @search.q = params[:q].to_s

      if params[:what].present?
        @search.what = params[:what]
      end
      if params[:order].present?
        @search.order = params[:order]
      end
      if params[:page].present?
        @search.page = params[:page].to_i
      end

      if @search.valid?
        begin
          @search.search_for_user!(@user)
        rescue ThinkingSphinx::ConnectionError
          flash[:error] = "Sorry, but the search engine is currently out " <<
            "of order"
        end
      end
    end

    render :action => "index"
  end
end
