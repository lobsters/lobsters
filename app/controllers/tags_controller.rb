# typed: false

class TagsController < ApplicationController
  before_action :show_title_h1

  def index
    @title = "Tags"

    @categories = Category.order(category: :asc).includes(:tags)
    @tags = Tag.all.preload(:category)

    @filtered_tags = filtered_tags.index_by(&:id)

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: @tags }
    end
  end
end
