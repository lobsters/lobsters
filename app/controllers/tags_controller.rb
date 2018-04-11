class TagsController < ApplicationController
  before_action :require_logged_in_admin, except: [:index]

  def index
    @cur_url = "/tags"
    @title = "Tags"

    @tags = Tag.all_with_story_counts_for(nil)

    respond_to do |format|
      format.html { render :action => "index" }
      format.json { render :json => @tags }
    end
  end

  def new
    @tag = Tag.new
    @title = "Create Tag"
  end

  def create
    tag = Tag.create(tag_params)
    if tag.valid?
      flash[:success] = "Tag #{tag.tag} has been created"
      redirect_to tags_path
    else
      flash[:error] = "New tag not created: #{tag.errors.full_messages.join(', ')}"
      redirect_to new_tag_path
    end
  end

  def edit
    @tag = Tag.find(params[:id])
    @title = "Edit Tag"
  end

  def update
    tag = Tag.find(params[:id])
    if tag.update(tag_params)
      flash[:success] = "Tag #{tag.tag} has been updated"
      redirect_to tags_path
    else
      flash[:error] = "Tag not updated: #{tag.errors.full_messages.join(', ')}"
      redirect_to edit_tag_path
    end
  end

private

  def tag_params
    params.require(:tag).permit(
      :tag,
      :description,
      :privileged,
      :inactive,
      :hotness_mod,
      action_name == 'create' ? :is_media : nil
    ).merge(edit_user_id: @user.id)
  end
end
