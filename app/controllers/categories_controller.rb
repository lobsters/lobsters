# typed: false

class CategoriesController < ApplicationController
  before_action :require_logged_in_admin

  def new
    @category = Category.new
    @title = "Create Category"
  end

  def create
    category = Category.create!(category_params)
    if category.valid?
      flash[:success] = "Category #{category.category} has been created"
      redirect_to tags_path
    else
      flash[:error] = "New category not created: #{category.errors.full_messages.join(", ")}"
      redirect_to new_category_path
    end
  end

  def edit
    @category = Category.where(category: params[:category_name]).first!
    @title = "Edit Category"
  end

  def update
    category = Category.where(category: params[:category_name]).first!
    if category.update(category_params)
      flash[:success] = "Category #{category.category} has been updated"
      redirect_to tags_path
    else
      flash[:error] = "Category not updated: #{category.errors.full_messages.join(", ")}"
      redirect_to edit_category_path
    end
  end

  private

  def category_params
    params.require(:category).permit(
      :category_name,
      :category
    ).merge(edit_user_id: @user.id)
  end
end
