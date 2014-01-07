class ModerationsController < ApplicationController
  def index
    @title = "Moderation Log"

    @moderations = Moderation.order("id desc").page(params[:page]).per(50)
  end
end
