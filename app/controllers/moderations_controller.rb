class ModerationsController < ApplicationController
  def index
    @title = t('.moderationlogtitle')

    @pages = (Moderation.count / 50).ceil
    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2 ** 32) || @page > @pages
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @moderations = Moderation.order("id desc").limit(50).offset((@page - 1) *
      50)
  end
end
