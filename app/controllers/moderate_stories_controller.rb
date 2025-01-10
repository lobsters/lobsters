class ModerateStoriesController < ApplicationController
  before_action :require_logged_in_moderator
  before_action :find_user_story!
  before_action :show_title_h1

  def edit
    @title = "Edit Story"

    if @story.merged_into_story
      @story.merge_story_short_id = @story.merged_into_story.short_id
      User.update_counters @story.user_id, karma: (@story.votes.count * -2)
    end
  end

  def update
    @story.is_deleted = false
    @story.editor = @user
    @story.attributes = story_params

    if @story.save
      redirect_to @story.comments_path
    else
      render action: "edit"
    end
  end

  private

  def story_params
    params.require(:story).permit(
      :title, :url, :description, :moderation_reason,
      :merge_story_short_id, :is_unavailable, :user_is_author, :user_is_following,
      tags_a: []
    )
  end

  def find_user_story!
    @story = Story.where(short_id: params[:story_id] || params[:id]).first
    if !@story
      raise ActiveRecord::RecordNotFound
    end
  end
end
