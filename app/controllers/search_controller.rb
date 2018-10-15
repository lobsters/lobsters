class SearchController < ApplicationController
  def index
    @title = I18n.t 'controllers.search_controller.searchtitle'
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
        rescue ThinkingSph::ConnectionError
          flash[:error] = I18n.t 'controllers.search_controller.flasherrorsearchcontroller'
        end
      end
    end

    render :action => "index"
  end
end
