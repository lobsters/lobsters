class TagsController < ApplicationController

  def index
    @cur_url = "/tags"
    @title = "Tags"

    render :action => "index"
  end

end
