# typed: false

class TagsController < ApplicationController
  before_action :require_logged_in_admin, except: [:index]
  before_action :show_title_h1, only: [:new, :edit]

  def index
    @title = "Tags"

    @categories = Category.order(category: :asc).includes(:tags)
    @tags = Tag.all

    @filtered_tags = if @user
      @user.tag_filter_tags.index_by(&:id)
    else
      tags_filtered_by_cookie.index_by(&:id)
    end

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: @tags }
    end
  end

  def new
    @tag = Tag.new
    @title = "Create Tag"
  end

  def create
    @title = "Create Tag"
    tag = Tag.create(tag_params)
    if tag.persisted?
      flash[:success] = "Tag #{tag.tag} has been created"
      redirect_to tags_path
    else
      flash[:error] = "New tag not created: #{tag.errors.full_messages.join(", ")}"
      redirect_to new_tag_path
    end
  end

  def edit
    @tag = Tag.where(tag: params[:tag_name]).first!
    @title = "Edit Tag"
  end

  def update
    tag = Tag.where(tag: params[:tag_name]).first!
    if tag.update(tag_params)
      flash[:success] = "Tag #{tag.tag} has been updated"
      redirect_to tags_path
    else
      flash[:error] = "Tag not updated: #{tag.errors.full_messages.join(", ")}"
      redirect_to edit_tag_path
    end
  end

  private

  def tag_params
    params.require(:tag).permit(
      :category_name,
      :tag,
      :tag_name,
      :description,
      :permit_by_new_users,
      :privileged,
      :is_media,
      :active,
      :hotness_mod
    ).merge(edit_user_id: @user.id)
  end
end
