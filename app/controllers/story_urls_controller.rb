# typed: false

class StoryUrlsController < ApplicationController
  def all
    url = params.require(:url)

    respond_to do |format|
      format.json {
        render json: Story.find_similar_by_url(url).for_presentation
      }
    end
  end

  def latest
    url = params.require(:url)

    similar_stories = Story.find_similar_by_url(url)
    if similar_stories.any?
      redirect_to similar_stories.first.comments_path
    elsif @user
      redirect_to new_story_path, url: url
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
