class CommentsController < ApplicationController
  COMMENTS_PER_PAGE = 20

  before_filter :require_logged_in_user_or_400,
    :only => [ :create, :preview, :preview_new, :upvote, :downvote, :unvote ]

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
        comment.parent_comment_id = pc.id
        # needed for carryng along in comment preview form
        comment.parent_comment_short_id = params[:parent_comment_short_id]
      else
        return render :json => { :error => "invalid parent comment",
          :status => 400 }
      end
    end

    # prevent double-clicks of the post button
    if !params[:preview].present? &&
    (pc = Comment.where(:story_id => story.id, :user_id => @user.id,
      :parent_comment_id => comment.parent_comment_id).first)
      if (Time.now - pc.created_at) < 5.minutes
        comment.errors.add(:comment, "^You have already posted a comment " <<
          "here recently.")

        return render :partial => "commentbox", :layout => false,
          :content_type => "text/html", :locals => { :comment => comment }
      end
    end

    if comment.valid? && !params[:preview].present? && comment.save
      comment.current_vote = { :vote => 1 }

      if comment.parent_comment_id
        render :partial => "postedreply", :layout => false,
          :content_type => "text/html", :locals => { :comment => comment }
      else
        render :partial => "commentbox", :layout => false,
          :content_type => "text/html", :locals => {
          :comment => story.comments.build, :show_comment => comment }
      end
    else
      comment.previewing = true
      comment.upvotes = 1
      comment.current_vote = { :vote => 1 }

      render :partial => "commentbox", :layout => false,
        :content_type => "text/html", :locals => {
        :comment => comment, :show_comment => comment }
    end
  end

  def preview_new
    params[:preview] = true
    return create
  end

  def edit
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => { :comment => comment }
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

    if comment.save
      # TODO: render the comment again properly, it's indented wrong

      render :partial => "postedreply", :layout => false,
        :content_type => "text/html", :locals => { :comment => comment }
    else
      comment.previewing = true
      comment.current_vote = { :vote => 1 }

      render :partial => "commentbox", :layout => false,
        :content_type => "text/html", :locals => {
        :comment => comment, :show_comment => comment }
    end
  end

  def preview
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.comment = params[:comment]

    comment.previewing = true
    comment.current_vote = { :vote => 1 }

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => {
      :comment => comment, :show_comment => comment }
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

    @page = 1
    if params[:page].to_i > 0
      @page = params[:page].to_i
    end

    @comments = Comment.where(
      :is_deleted => false, :is_moderated => false
    ).order(
      "created_at DESC"
    ).offset(
      (@page - 1) * COMMENTS_PER_PAGE
    ).limit(
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

    @threads = @showing_user.recent_threads(20).map{|r|
      cs = Comment.where(
        :thread_id => r
      ).includes(
        :user, :story
      ).arrange_for_user(
        @showing_user
      )

      if @user && (@showing_user.id == @user.id)
        @votes = Vote.comment_votes_by_user_for_story_hash(@user.id,
          cs.map{|c| c.story_id }.uniq)

        cs.each do |c|
          if @votes[c.id]
            c.current_vote = @votes[c.id]
          end
        end
      else
        @votes = []
      end

      cs
    }

    # trim each thread to this user's first response
    # XXX: busted
if false
    @threads.map!{|th|
      th.each do |c|
        if c.user_id == @user.id
          break
        else
          th.shift
        end
      end

      th
    }
end

    @comments = @threads.flatten
  end

private

  def find_comment
    Comment.where(:short_id => params[:comment_id]).first
  end
end
