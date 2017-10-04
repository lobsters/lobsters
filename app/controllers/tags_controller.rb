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
    tag = Tag.create!(params.require(:tag).permit(:tag, :description, :privileged, :is_media, :inactive, :hotness_mod))
    flash[:success] = "Tag #{tag.tag} has been created"
    redirect_to tags_path
  end

  def edit
    @tag = Tag.find(params[:id])
    @title = "Edit Tag"
  end

  def update
    attrs = params.require(:tag).permit(:tag, :description, :privileged, :inactive, :hotness_mod)
    Tag.find(params[:id]).update!(attrs)
    flash[:success] = "Tag #{attrs[:tag]} has been updated"
    redirect_to tags_path
  end
end
