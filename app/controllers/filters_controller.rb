class FiltersController < ApplicationController
  before_action :authenticate_user
  before_action :show_title_h1

  def index
    @title = "Filtered Tags"

    @categories = Category.all
                          .order('category asc, tags.tag asc')
                          .eager_load(:tags)
                          .references(:tags)
                          .where('tags.active = true')

    # perf: three queries is much faster than joining, grouping on tags.id for counts
    @story_counts = Tagging.group(:tag_id).count
    @filter_counts = TagFilter.group(:tag_id).count

    if @user
      @filtered_tags = @user.tag_filter_tags.index_by(&:id)
    else
      @filtered_tags = tags_filtered_by_cookie.index_by(&:id)
    end
  end

  def update
    new_tags = Tag.active.where(:tag => (params[:tags] || {}).keys).to_a
    new_tags.keep_if {|t| t.user_can_filter? @user }

    if @user
      @user.tag_filter_tags = new_tags
    else
      cookies.permanent[TAG_FILTER_COOKIE] = new_tags.map(&:tag).join(",")
    end

    flash[:success] = "Your filters have been updated."

    redirect_to filters_path
  end
end
