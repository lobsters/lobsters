# typeed: false

class Mod::TagsController < Mod::ModController
  before_action :require_logged_in_admin

  def new
    @tag = Tag.new
    @title = "Create Tag"
  end

  def create
    @title = "Create Tag"
    tag = Tag.create(tag_params)
    if tag.persisted?
      flash[:success] = "Tag #{tag.tag} created"
      redirect_to tag_path(tag)
    else
      flash[:error] = "New tag not created: #{tag.errors.full_messages.join(", ")}"
      render :new
    end
  end

  def edit
    @tag = Tag.where(tag: params[:id]).first!
    @title = "Edit Tag"
  end

  def update
    tag = Tag.where(tag: params[:id]).first!
    if tag.update(tag_params)
      flash[:success] = "Tag #{tag.tag} has been updated"
      redirect_to tag_path(tag)
    else
      flash[:error] = "Tag not updated: #{tag.errors.full_messages.join(", ")}"
      redirect_to edit_mod_tag_path
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
