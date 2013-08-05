class FiltersController < ApplicationController
  before_filter :authenticate_user

  def index
    @cur_url = "/filters"
    @title = "Filtered Tags"

    if @user
      @filtered_tags = @user.tag_filters.reload
    else
      @filtered_tags = tags_filtered_by_cookie.map{|t|
        tf = TagFilter.new
        tf.tag = t
        tf
      }
    end

    render :action => "index"
  end

  def update
    new_filters = []

    params.each do |k,v|
      if (m = k.match(/^tag_(.+)$/)) && v.to_i == 1 &&
      (t = Tag.find_by_tag(m[1])) && t.valid_for?(@user)
        new_filters.push m[1]
      end
    end

    if @user
      @user.tag_filters(:include => :tag).each do |tf|
        if tf.tag && new_filters.include?(tf.tag.tag)
          new_filters.reject!{|t| t == tf.tag.tag }
        else
          tf.destroy
        end
      end

      new_filters.each do |t|
        tf = TagFilter.new
        tf.user_id = @user.id
        tf.tag_id = Tag.find_by_tag(t).id
        tf.save!
      end
    else
      cookies.permanent[TAG_FILTER_COOKIE] = new_filters.join(",")
    end

    flash[:success] = "Your filters have been updated."
    return redirect_to "/filters"
  end
end
