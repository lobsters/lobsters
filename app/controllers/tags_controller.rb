class TagsController < ApplicationController
  def index
    return render :json => Tag.active.all
  end
end
