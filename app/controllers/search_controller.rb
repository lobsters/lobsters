class SearchController < ApplicationController
  before_action :load_search_backend

  def index
    @title = "Search"
    @cur_url = "/search"

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
        @search.search_for_user!(@user)
      end
    end

    render :action => "index"
  end

private

  def load_search_backend
    @search = if Rails.application.use_elasticsearch?
      ElasticSearch.new
    else
      SqlSearch.new
    end
  end
end
