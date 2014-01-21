class CommentsController < ApplicationController
  COMMENTS_PER_PAGE = 20

  before_filter :require_logged_in_user_or_400,
    :only => [ :create, :preview, :upvote, :downvote, :unvote ]

  # for rss feeds, load the user's tag filters if a token is passed
  before_filter :find_user_from_rss_token, :only => [ :index ]

  def create
    if !(story = Story.where(:short_id => params[:story_id]).first) ||
    story.is_gone?
      return render :text => "can't find story", :status => 400
    end

    comment = story.comments.build
    comment.comment = params[:comment].to_s
    comment.user = @user

    if params[:parent_comment_short_id].present?
      if pc = Comment.where(:story_id => story.id, :short_id =>
      params[:parent_comment_short_id]).first
        comment.parent_comment = pc
      else
        return render :json => { :error => "invalid parent comment",
          :status => 400 }
      end
    end

    # prevent double-clicks of the post button
    if params[:preview].blank? &&
    (pc = Comment.where(:story_id => story.id, :user_id => @user.id,
      :parent_comment_id => comment.parent_comment_id).first)
      if (Time.now - pc.created_at) < 5.minutes
        comment.errors.add(:comment, "^You have already posted a comment " <<
          "here recently.")

        return render :partial => "commentbox", :layout => false,
          :content_type => "text/html", :locals => { :comment => comment }
      end
    end

    if comment.valid? && params[:preview].blank? && comment.save
      comment.current_vote = { :vote => 1 }

      render :partial => "comments/postedreply", :layout => false,
        :content_type => "text/html", :locals => { :comment => comment }
    else
      comment.upvotes = 1
      comment.current_vote = { :vote => 1 }

      preview comment
    end
  end

  def edit
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def reply
    if !(parent_comment = find_comment)
      return render :text => "can't find comment", :status => 400
    end

    comment = Comment.new
    comment.story = parent_comment.story
    comment.parent_comment = parent_comment

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment,
      :cancellable => true }
  end

  def delete
    if !((comment = find_comment) && comment.is_deletable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.delete_for_user(@user)

    render :partial => "comment", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def undelete
    if !((comment = find_comment) && comment.is_undeletable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.undelete_for_user(@user)

    render :partial => "comment", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
  end

  def update
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.comment = params[:comment]

    if params[:preview].blank? && comment.save
      votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id,
        [comment.id])
      comment.current_vote = votes[comment.id]

      render :partial => "comments/comment", :layout => false,
        :content_type => "text/html", :locals => { :comment => comment }
    else
      comment.current_vote = { :vote => 1 }

      preview comment
    end
  end

  def unvote
    if !(comment = find_comment)
      return render :text => "can't find comment", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, comment.story_id,
      comment.id, @user.id, nil)

    render :text => "ok"
  end

  def upvote
    if !(comment = find_comment)
      return render :text => "can't find comment", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, comment.story_id,
      comment.id, @user.id, params[:reason])

    render :text => "ok"
  end

  def downvote
    if !(comment = find_comment)
      return render :text => "can't find comment", :status => 400
    end

    if !Vote::COMMENT_REASONS[params[:reason]]
      return render :text => "invalid reason", :status => 400
    end

    if !@user.can_downvote?
      return render :text => "not permitted to downvote", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(-1, comment.story_id,
      comment.id, @user.id, params[:reason])

    render :text => "ok"
  end

  def index
    @rss_link ||= "<link rel=\"alternate\" type=\"application/rss+xml\" " <<
      "title=\"RSS 2.0\" href=\"/comments.rss" <<
      (@user ? "?token=#{@user.rss_token}" : "") << "\" />"

    @heading = @title = "Newest Comments"
    @cur_url = "/comments"

    @comments = Comment.where(
      :is_deleted => false, :is_moderated => false
    ).order(
      "created_at DESC"
    ).page(
      params[:page],
    ).per(
      COMMENTS_PER_PAGE
    ).includes(
      :user, :story
    )

    if @user
      @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id,
        @comments.map{|c| c.id })

      @comments.each do |c|
        if @votes[c.id]
          c.current_vote = @votes[c.id]
        end
      end
    end
  end

  def threads
    if params[:user]
      @showing_user = User.where(:username => params[:user]).first!
      @heading = @title = "Threads for #{@showing_user.username}"
      @cur_url = "/threads/#{@showing_user.username}"
    elsif !@user
      # TODO: show all recent threads
      return redirect_to "/login"
    else
      @showing_user = @user
      @heading = @title = "Your Threads"
      @cur_url = "/threads"
    end

    thread_ids = @showing_user.recent_threads(20)

    comments = Comment.where(
      :thread_id => thread_ids
    ).includes(
      :user, :story
    ).arrange_for_user(
      @showing_user
    )

    comments_by_thread_id = comments.group_by(&:thread_id)
    @threads = comments_by_thread_id.values_at(*thread_ids).compact

    if @user && (@showing_user.id == @user.id)
      @votes = Vote.comment_votes_by_user_for_story_hash(@user.id,
        comments.map(&:story_id).uniq)

      comments.each do |c|
        if @votes[c.id]
          c.current_vote = @votes[c.id]
        end
      end
    end

    # trim each thread to this user's first response
    # XXX: busted
    #@threads.each do |th|
    #  th.each do |c|
    #    if c.user_id == @user.id
    #      break
    #    else
    #      th.shift
    #    end
    #  end
    #end
  end

private

  def preview(comment)
    comment.previewing = true
    comment.is_deleted = false # show normal preview for deleted comments

    render :partial => "comments/commentbox", :layout => false,
      :content_type => "text/html", :locals => {
      :comment => comment, :show_comment => comment }
  end

  def find_comment
    Comment.where(:short_id => params[:id]).first
  end
end
