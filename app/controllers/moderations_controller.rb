class ModerationsController < ApplicationController
  def index
    @title = "Moderation Log"

    @pages = Moderation.count
    @page = params[:page] ? params[:page].to_i : 0

    if @page < 1
      @page = 1
    end

    @moderations = Moderation.order("id desc").limit(50).offset((@page - 1) *
      50).all
  end
end
