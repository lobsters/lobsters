class CommentsController < ApplicationController
  COMMENTS_PER_PAGE = 20

  caches_page :index, :threads, if: CACHE_PAGE

  before_action :require_logged_in_user_or_400,
                :only => [:create, :preview, :upvote, :flag, :unvote]
  before_action :require_logged_in_user, :only => [:upvoted]
  before_action :flag_warning, only: [:threads]
  before_action :show_title_h1

  # for rss feeds, load the user's tag filters if a token is passed
  before_action :find_user_from_rss_token, :only => [:index]

  def create
    if !(story = Story.where(:short_id => params[:story_id]).first) ||
       story.is_gone?
      return render :plain => "can't find story", :status => 400
    end

    comment = story.comments.build
    comment.comment = params[:comment].to_s
    comment.user = @user

    if params[:hat_id] && @user.wearable_hats.where(:id => params[:hat_id])
      comment.hat_id = params[:hat_id]
    end

    if params[:parent_comment_short_id].present?
      if (pc = Comment.where(:story_id => story.id, :short_id => params[:parent_comment_short_id])
        .first)
        comment.parent_comment = pc
      else
        return render :json => { :error => "invalid parent comment", :status => 400 }
      end
    end

    # sometimes on slow connections people resubmit; silently accept it
    if (already = Comment.find_by(user: comment.user,
                                  story: comment.story,
                                  parent_comment_id: comment.parent_comment_id,
                                  comment: comment.comment))
      self.render_created_comment(already)
      return
    end

    # rate-limit users to one reply per 5m per parent comment
    if params[:preview].blank? &&
       (pc = Comment.where(:story_id => story.id,
                           :user_id => @user.id,
                           :parent_comment_id => comment.parent_comment_id).first)
      if (Time.current - pc.created_at) < 5.minutes && !@user.is_moderator?
        comment.errors.add(:comment, "^You have already posted a comment " <<
          "here recently.")

        return render :partial => "commentbox", :layout => false,
          :content_type => "text/html", :locals => { :comment => comment }
      end
    end

    if comment.valid? && params[:preview].blank? && ActiveRecord::Base.transaction { comment.save }
      comment.current_vote = { :vote => 1 }
      self.render_created_comment(comment)
    else
      comment.score = 1
      comment.current_vote = { :vote => 1 }

      preview comment
    end
  end

  def render_created_comment(comment)
    if request.xhr?
      render :partial => "comments/postedreply", :layout => false,
        :content_type => "text/html", :locals => { :comment => comment }
    else
      redirect_to comment.path
    end
  end

  def show
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render :plain => "can't find comment", :status => 400
    end

    render :partial => "comment",
           :layout => false,
           :content_type => "text/html",
           :locals => {
             :comment => comment,
             :show_tree_lines => params[:show_tree_lines],
           }
  end

  def show_short_id
    if !(comment = find_comment)
      return render :plain => "can't find comment", :status => 400
    end

    render :json => comment.as_json
  end

  def redirect_from_short_id
    if (comment = find_comment)
      return redirect_to comment.path
    else
      return render :plain => "can't find comment", :status => 400
    end
  end

  def edit
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render :plain => "can't find comment", :status => 400
    end

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def reply
    if !(parent_comment = find_comment)
      return render :plain => "can't find comment", :status => 400
    end

    comment = Comment.new
    comment.story = parent_comment.story
    comment.parent_comment = parent_comment

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def delete
    if !((comment = find_comment) && comment.is_deletable_by_user?(@user))
      return render :plain => "can't find comment", :status => 400
    end

    comment.delete_for_user(@user, params[:reason])

    render :partial => "comment", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def undelete
    if !((comment = find_comment) && comment.is_undeletable_by_user?(@user))
      return render :plain => "can't find comment", :status => 400
    end

    comment.undelete_for_user(@user)

    render :partial => "comment", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def disown
    if !((comment = find_comment) && comment.is_disownable_by_user?(@user))
      return render :plain => "can't find comment", :status => 400
    end

    InactiveUser.disown! comment
    comment = find_comment

    render :partial => "comment", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def update
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render :plain => "can't find comment", :status => 400
    end

    comment.comment = params[:comment]
    comment.hat_id = nil
    if params[:hat_id] && @user.wearable_hats.where(:id => params[:hat_id])
      comment.hat_id = params[:hat_id]
    end

    if params[:preview].blank? && comment.save
      votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, [comment.id])
      comment.current_vote = votes[comment.id]

      render :partial => "comments/comment",
             :layout => false,
             :content_type => "text/html",
             :locals => { :comment => comment, :show_tree_lines => params[:show_tree_lines] }
    else
      comment.current_vote = { :vote => 1 }

      preview comment
    end
  end

  def unvote
    if !(comment = find_comment) || comment.is_gone?
      return render :plain => "can't find comment", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      0, comment.story_id, comment.id, @user.id, nil
    )

    render :plain => "ok"
  end

  def upvote
    if !(comment = find_comment) || comment.is_gone?
      return render :plain => "can't find comment", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      1, comment.story_id, comment.id, @user.id, params[:reason]
    )

    render :plain => "ok"
  end

  def flag
    if !(comment = find_comment) || comment.is_gone?
      return render :plain => "can't find comment", :status => 400
    end

    if !Vote::COMMENT_REASONS[params[:reason]]
      return render :plain => "invalid reason", :status => 400
    end

    if !@user.can_flag?(comment)
      return render :plain => "not permitted to flag", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      -1, comment.story_id, comment.id, @user.id, params[:reason]
    )

    render :plain => "ok"
  end

  def index
    @rss_link ||= {
      :title => "RSS 2.0 - Newest Comments",
      :href => "/comments.rss" + (@user ? "?token=#{@user.rss_token}" : ""),
    }

    @title = "Newest Comments"

    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2 ** 32)
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @comments = Comment.accessible_to_user(@user)
      .not_on_story_hidden_by(@user)
      .order("id DESC")
      .includes(:user, :hat, :story => :user)
      .joins(:story).where.not(stories: { is_deleted: true })
      .limit(COMMENTS_PER_PAGE)
      .offset((@page - 1) * COMMENTS_PER_PAGE)

    if @user
      @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, @comments.map(&:id))

      @comments.each do |c|
        if @votes[c.id]
          c.current_vote = @votes[c.id]
        end
      end
    end

    respond_to do |format|
      format.html { render :action => "index" }
      format.rss {
        if @user && params[:token].present?
          @title = "Private comments feed for #{@user.username}"
        end

        render :action => "index", :layout => false
      }
    end
  end

  def upvoted
    @rss_link ||= {
      :title => "RSS 2.0 - Newest Comments",
      :href => upvoted_comments_path(format: :rss) + (@user ? "?token=#{@user.rss_token}" : ""),
    }

    @title = "Upvoted Comments"
    @above = 'saved/subnav'

    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2 ** 32)
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @comments = Comment.accessible_to_user(@user)
      .where.not(user_id: @user.id)
      .order("id DESC")
      .includes(:user, :hat, :story => :user)
      .joins(:votes).where(votes: { user_id: @user.id, vote: 1 })
      .joins(:story).where.not(stories: { is_deleted: true })
      .limit(COMMENTS_PER_PAGE)
      .offset((@page - 1) * COMMENTS_PER_PAGE)

    # TODO: respect hidden stories

    @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, @comments.map(&:id))
    @comments.each do |c|
      c.current_vote = @votes[c.id]
    end

    respond_to do |format|
      format.html { render action: :index }
      format.rss {
        if @user && params[:token].present?
          @title = "Upvoted comments feed for #{@user.username}"
        end

        render :action => "index", :layout => false
      }
    end
  end

  def threads
    if params[:user]
      @showing_user = User.find_by!(username: params[:user])
      @title = "Threads for #{@showing_user.username}"
    elsif !@user
      return redirect_to active_path
    else
      @showing_user = @user
      @title = "Your Threads"
    end

    thread_ids = @showing_user.recent_threads(
      20,
      include_submitted_stories: !!(@user && @user.id == @showing_user.id),
      for_user: @user
    )

    comments = Comment.accessible_to_user(@user)
      .where(:thread_id => thread_ids)
      .includes(:user, :hat, :story => :user, :votes => :user)
      .joins(:story).where.not(stories: { is_deleted: true })
      .arrange_for_user(@user)

    comments_by_thread_id = comments.group_by(&:thread_id)
    @threads = comments_by_thread_id.values_at(*thread_ids).compact

    if @user
      @votes = Vote.comment_votes_by_user_for_story_hash(@user.id, comments.map(&:story_id).uniq)

      comments.each do |c|
        if @votes[c.id]
          c.current_vote = @votes[c.id]
        end
      end
    end
  end

private

  def preview(comment)
    comment.previewing = true
    comment.is_deleted = false # show normal preview for deleted comments

    render :partial => "comments/commentbox",
           :layout => false,
           :content_type => "text/html",
           :locals => {
             :comment => comment,
             :show_comment => comment,
             :show_tree_lines => params[:show_tree_lines],
           }
  end

  def find_comment
    comment = Comment.where(short_id: params[:id]).first
    if @user && comment
      comment.current_vote = Vote.where(:user_id => @user.id,
        :story_id => comment.story_id, :comment_id => comment.id).first
    end

    comment
  end
end
