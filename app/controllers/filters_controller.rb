class FiltersController < ApplicationController
  before_filter :authenticate_user

  def index
    @cur_url = "/filters"
    @title = "Filtered Tags"

    @tags = Tag.order(:tag).accessible_to(@user)

    if @user
      @filtered_tags = @user.tag_filter_tags.to_a
    else
      @filtered_tags = tags_filtered_by_cookie.to_a
    end
  end

  def update
    tags_param = params.permit(:tags => [])[:tags]
    new_tags = tags_param.blank? ? [] : Tag.where(:tag => tags_param).to_a
    new_tags.keep_if {|t| t.valid_for? @user }

    if @user
      @user.tag_filter_tags = new_tags
    else
      cookies.permanent[TAG_FILTER_COOKIE] = new_tags.map(&:tag).join(",")
    end

    flash[:success] = "Your filters have been updated."

    redirect_to filters_path
  end
end
