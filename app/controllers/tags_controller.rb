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
    tag = Tag.create(params.require(:tag).permit(:tag, :description, :privileged, :is_media, :inactive, :hotness_mod))
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
    attrs = params.require(:tag).permit(:tag, :description, :privileged, :inactive, :hotness_mod)
    tag = Tag.find(params[:id])
    if tag.update(attrs)
      flash[:success] = "Tag #{attrs[:tag]} has been updated"
      redirect_to tags_path
    else
      flash[:error] = "Tag not updated: #{tag.errors.full_messages.join(', ')}"
      redirect_to edit_tag_path
    end
  end
end
