class Api::TagsController < ApplicationController


 
  def find_stories_by_tags
    @stories = []
    @tags_not_found =[]
    @tag_id = []

    tag_params = params[:tag].split(',')

    # get tag's ids if tag exists or add to "not_found" array
    tag_params.each do |tag|
      begin
        @tag_id << Tag.where(tag: tag)[0].id
      rescue => exception
        @tags_not_found << tag
      end
    end

    # find all storie's ids which contain tag's id
    @story_ids = Tagging.where(tag_id: @tag_id)

    # find all stories by id
    @story_ids.each  do |i|
      @stories << Story.find_by(id: i.id)
    end

    render json: {"response" => @stories, "not_found" => @tags_not_found}
  end
end