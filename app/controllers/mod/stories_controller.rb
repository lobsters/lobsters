class Mod::StoriesController < Mod::ModeratorController
  include StoryFinder

  before_action :find_story!
  before_action :show_title_h1

  def edit
    @title = "Edit Story"

    if @story.merged_into_story
      @story.merge_story_short_id = @story.merged_into_story.short_id
      User.update_counters @story.user_id, karma: (@story.votes.count * -2)
    end
  end

  def update
    @story.last_edited_at = Time.current
    @story.is_deleted = false
    @story.editor = @user
    update_story_attributes

    if @story.save
      redirect_to @story.comments_path
    else
      render action: "edit"
    end
  end

  def undelete
    @story.is_deleted = false
    @story.editor = @user
    update_story_attributes

    if @story.save
      Keystore.increment_value_for("user:#{@story.user.id}:stories_deleted", -1)
    end

    redirect_to @story.comments_path
  end

  def destroy
    update_story_attributes

    if @story.user_id != @user.id && @story.moderation_reason.blank?
      @story.errors.add(:moderation_reason, message: "is required")
      return render action: "edit"
    end

    @story.is_deleted = true
    @story.editor = @user

    if @story.save
      Keystore.increment_value_for("user:#{@story.user.id}:stories_deleted")
      Mastodon.delete_post(@story)
    end

    redirect_to @story.comments_path
  end

  private

  def story_params
    ps = params.require(:story).permit(
      :title, :url, :description, :moderation_reason,
      :merge_story_short_id, :is_unavailable, :user_is_author, :user_is_following,
      tags: []
    )
    ps[:tags] = Tag.where(tag: ps[:tags] || @story.tags.map(&:tag))
    ps
  end

  def update_story_attributes
    @story.tags_was = @story.tags.to_a
    @story.attributes = story_params
  end
end
