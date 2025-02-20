class SuggestionsController < ApplicationController
  include StoryFinder

  before_action :find_story!, only: [:new, :create]
  before_action :require_logged_in_user, only: [:new]
  before_action :show_title_h1, only: [:new]

  def create
    if !@story.can_have_suggestions_from_user?(@user)
      flash[:error] = "You are not allowed to offer suggestions on that story."
      return redirect_to @story.comments_path
    end

    story_user = @story.user
    inappropriate_tags = Tag
      .where(tag: params[:story][:tags])
      .reject { |t| t.can_be_applied_by?(story_user) }
    if inappropriate_tags.length > 0
      tag_error = ""
      inappropriate_tags.each do |t|
        tag_error += if t.privileged?
          "User #{story_user.username} cannot suggest tag #{t.tag} as they are not a " \
            "moderator, so it has been removed from your suggestion.\n"
        elsif !t.permit_by_new_users?
          "User #{story_user.username} cannot suggest tag #{t.tag} due to being a new " \
            "user, so it has been removed from your suggestion.\n"
        elsif !t.active?
          "Cannot suggest tag #{t.tag} because it's inactive"
        else
          "User #{story_user.username} cannot suggest tag #{t.tag} " \
            "so it has been removed from your suggestion.\n"
        end
      end
      tag_error += ""
      flash[:error] = tag_error
    end

    ostory = @story.dup

    @story.title = params[:story][:title]
    if @story.valid?
      dsug = false
      if @story.title != ostory.title
        @story.save_suggested_title_for_user!(@story.title, @user)
        dsug = true
      end

      sugtags = Tag
        .where(tag: params[:story][:tags])
        .reject { |t| !t.can_be_applied_by?(story_user) }
        .map { |s| s.tag }
      if @story.tags.map(&:tag).sort != sugtags.sort
        @story.save_suggested_tags_for_user!(sugtags, @user)
        dsug = true
      end

      if dsug
        ostory = @story.reload
        flash[:success] = "Your suggested changes have been noted."
      end
      redirect_to ostory.comments_path
    else
      render action: "suggest"
    end
  end

  def new
    @title = "Suggest Story Changes"
    if !@story.can_have_suggestions_from_user?(@user)
      flash[:error] = "You are not allowed to offer suggestions on that story."
      return redirect_to @story.comments_path
    end

    if (suggested_tags = @story.suggested_taggings.where(user_id: @user.id)).any?
      @story.tags = suggested_tags.map(&:tag)
    end
    if (tt = @story.suggested_titles.where(user_id: @user.id).first)
      @story.title = tt.title
    end
  end
end
