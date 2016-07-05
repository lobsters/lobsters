class ModerationsController < ApplicationController
  def index
    @title = t('.moderationlogtitle')

    @page = params[:page] ? params[:page].to_i : 0
    @pages = (Moderation.count / 50).ceil

    if @page < 1
      @page = 1
    elsif @page > @pages
      @page = @pages
    end

    @moderations = Moderation.order("id desc").limit(50).offset((@page - 1) *
      50)
  end
end
