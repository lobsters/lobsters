class CommentsController < ApplicationController
  COMMENTS_PER_PAGE = 20

  before_filter :require_logged_in_user_or_400,
    :only => [ :create, :preview, :preview_new, :upvote, :downvote, :unvote ]

  # for rss feeds, load the user's tag filters if a token is passed
  before_filter :find_user_from_rss_token, :only => [ :index ]

  def create
    if !(story = Story.find_by_short_id(params[:story_id])) || story.is_gone?
      return render :text => "can't find story", :status => 400
    end

    comment = Comment.new
    comment.comment = params[:comment].to_s
    comment.story_id = story.id
    comment.user_id = @user.id

    if params[:parent_comment_short_id].present?
      if pc = Comment.find_by_story_id_and_short_id(story.id,
      params[:parent_comment_short_id])
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
    (pc = Comment.find_by_story_id_and_user_id_and_parent_comment_id(story.id,
    @user.id, comment.parent_comment_id))
      if (Time.now - pc.created_at) < 5.minutes
        comment.errors.add(:comment, "^You have already posted a comment " <<
          "here recently.")

        return render :partial => "commentbox", :layout => false,
          :content_type => "text/html", :locals => { :story => story,
          :comment => comment }
      end
    end

    if comment.valid? && !params[:preview].present? && comment.save
      comment.current_vote = { :vote => 1 }

      if comment.parent_comment_id
        render :partial => "postedreply", :layout => false,
          :content_type => "text/html", :locals => { :story => story,
          :show_comment => comment }
      else
        render :partial => "commentbox", :layout => false,
          :content_type => "text/html", :locals => { :story => story,
          :comment => Comment.new, :show_comment => comment }
      end
    else
      comment.previewing = true
      comment.upvotes = 1
      comment.current_vote = { :vote => 1 }

      render :partial => "commentbox", :layout => false,
        :content_type => "text/html", :locals => { :story => story,
        :comment => comment, :show_comment => comment }
    end
  end

  def preview_new
    params[:preview] = true
    return create
  end

  def edit
    if !((comment = Comment.find_by_short_id(params[:comment_id])) &&
    comment.is_editable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => { :story => comment.story,
      :comment => comment }
  end

  def delete
    if !((comment = Comment.find_by_short_id(params[:comment_id])) &&
    comment.is_deletable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.delete_for_user(@user)

    render :partial => "comment", :layout => false,
      :content_type => "text/html", :locals => { :story => comment.story,
      :comment => comment }
  end

  def undelete
    if !((comment = Comment.find_by_short_id(params[:comment_id])) &&
    comment.is_undeletable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.undelete_for_user(@user)

    render :partial => "comment", :layout => false,
      :content_type => "text/html", :locals => { :story => comment.story,
      :comment => comment }
  end

  def update
    if !((comment = Comment.find_by_short_id(params[:comment_id])) &&
    comment.is_editable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.comment = params[:comment]

    if comment.save
      # TODO: render the comment again properly, it's indented wrong

      render :partial => "postedreply", :layout => false,
        :content_type => "text/html", :locals => { :story => comment.story,
        :show_comment => comment }
    else
      comment.previewing = true
      comment.current_vote = { :vote => 1 }

      render :partial => "commentbox", :layout => false,
        :content_type => "text/html", :locals => { :story => comment.story,
        :comment => comment, :show_comment => comment }
    end
  end

  def preview
    if !((comment = Comment.find_by_short_id(params[:comment_id])) &&
    comment.is_editable_by_user?(@user))
      return render :text => "can't find comment", :status => 400
    end

    comment.comment = params[:comment]

    comment.previewing = true
    comment.current_vote = { :vote => 1 }

    render :partial => "commentbox", :layout => false,
      :content_type => "text/html", :locals => { :story => comment.story,
      :comment => comment, :show_comment => comment }
  end

  def unvote
    if !(comment = Comment.find_by_short_id(params[:comment_id]))
      return render :text => "can't find comment", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, comment.story_id,
      comment.id, @user.id, nil)

    render :text => "ok"
  end

  def upvote
    if !(comment = Comment.find_by_short_id(params[:comment_id]))
      return render :text => "can't find comment", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, comment.story_id,
      comment.id, @user.id, params[:reason])

    render :text => "ok"
  end

  def downvote
    if !(comment = Comment.find_by_short_id(params[:comment_id]))
      return render :text => "can't find comment", :status => 400
    end

    if !Vote::COMMENT_REASONS[params[:reason]]
      return render :text => "invalid reason", :status => 400
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

    @comments = Comment.find(
      :all,
      :conditions => "is_deleted = 0 AND is_moderated = 0",
      :order => "created_at DESC",
      :offset => ((@page - 1) * COMMENTS_PER_PAGE),
      :limit => COMMENTS_PER_PAGE,
      :include => [ :user, :story ])

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
      @showing_user = User.find_by_username!(params[:user])
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
      cs = Comment.ordered_for_story_or_thread_for_user(nil, r, @showing_user)

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
end
