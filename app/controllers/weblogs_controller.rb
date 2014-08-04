class WeblogsController < ApplicationController
  before_filter { @page = page }

  WEBLOGS_PER_PAGE = 10

  def index
    @pages = (Weblog.count / WEBLOGS_PER_PAGE.to_f).ceil
    if @page > @pages
      @page = @pages
    end
    @show_more = @page < @pages

    @weblogs = Weblog.order("created_at DESC").
      offset((@page - 1) * WEBLOGS_PER_PAGE).
      limit(WEBLOGS_PER_PAGE)

    render :action => "index"
  end

private
  def page
    params[:page].to_i > 0 ? params[:page].to_i : 1
  end
end
