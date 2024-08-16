# typed: false

class StoryUrlsController < ApplicationController
  def all
    url = params.require(:url)
    raise ActionController::ParameterMissing.new("No URL") if url.blank?
    respond_to do |format|
      format.json {
        render json: Story.find_similar_by_url(url).map(&:as_json)
      }
    end
  end

  def latest
    url = params.require(:url)
    raise ActionController::ParameterMissing.new("No URL") if url.blank?

    similar_stories = Story.find_similar_by_url(url)
    redirect_to similar_stories[0].comments_path unless similar_stories.empty?
  end
end
