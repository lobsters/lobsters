class TagsController < ApplicationController
  def index
    @tags = Tag.all_with_story_counts_for(nil)

    respond_to do |format|
      format.html { render :action => "index" }
      format.json { render :json => @tags }
    end
  end
end
