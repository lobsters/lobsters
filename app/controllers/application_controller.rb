class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user

  def authenticate_user
    if session[:u]
      @user = User.find_by_session_token(session[:u])
    end

    true
  end

  def require_logged_in_user
    if @user
      true
    else
      redirect_to "/login"
    end
  end

  def require_logged_in_user_or_400
    if @user
      true
    else
      render :text => "not logged in", :status => 400
      return false
    end
  end

  def find_stories_for_user_and_tag_and_newest(user, tag = nil, newest = false)
    stories = []

    conds = [ "is_expired = 0 " ]

    if user && !newest
      # exclude downvoted items
      conds[0] << "AND stories.id NOT IN (SELECT story_id FROM votes " <<
        "WHERE user_id = ? AND vote < 0) "
      conds.push user.id
    end

    if tag
      conds[0] << "AND taggings.tag_id = ?"
      conds.push tag.id
      stories = Story.find(:all, :conditions => conds,
        :include => [ :user, { :taggings => :tag } ], :limit => 30)
    else
      stories = Story.find(:all, :conditions => conds,
        :include => [ :user, { :taggings => :tag } ], :limit => 30)
    end

    if user
      votes = Vote.votes_by_user_for_stories_hash(user.id,
        stories.map{|s| s.id })

      stories.each do |s|
        if votes[s.id]
          s.vote = votes[s.id]
        end
      end
    end

    if newest
      # TODO: better algorithm here
      stories.sort_by!{|s| s.created_at }.reverse!
    else
      stories.sort_by!{|s| s.hotness }
    end

    stories
  end
end
