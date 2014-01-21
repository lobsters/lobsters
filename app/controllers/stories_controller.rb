class StoriesController < ApplicationController
  before_filter :require_logged_in_user_or_400,
    :only => [ :upvote, :downvote, :unvote, :preview ]

  before_filter :require_logged_in_user, :only => [ :destroy, :create, :edit,
    :fetch_url_title, :new ]

  before_filter :find_user_story, :only => [ :destroy, :edit, :undelete,
    :update ]

  def create
    @title = "Submit Story"
    @cur_url = "/stories/new"

    # we don't allow the url to be changed, so we have to set it manually
    @story = Story.new(params[:story].reject{|k,v| k == "url" })
    @story.url = params[:story][:url]
    @story.user_id = @user.id

    if @story.valid? && !(@story.already_posted_story && !@story.seen_previous)
      if @story.save
        Vote.vote_thusly_on_story_or_comment_for_user_because(1, @story,
          nil, @user.id, nil)

        Countinual.count!("#{Rails.application.shortname}.stories.submitted",
          "+1")

        return redirect_to @story.comments_url
      end
    end

    return render :action => "new"
  end

  def destroy
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @story.is_expired = true
    @story.editor_user_id = @user.id

    if params[:reason].present? && @story.user_id != @user.id
      @story.moderation_reason = params[:reason]
    end

    @story.save(:validate => false)

    redirect_to @story.comments_url
  end

  def edit
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @title = "Edit Story"
  end

  def fetch_url_title
    s = Story.new
    s.url = params[:fetch_url]

    if (title = s.fetched_title(request.remote_ip)).present?
      return render :json => { :title => title }
    else
      return render :json => "error"
    end
  end

  def new
    @title = "Submit Story"
    @cur_url = "/stories/new"

    @story = Story.new

    if params[:url].present?
      @story.url = params[:url]

      if s = Story.find_similar_by_url(@story.url)
        if s.is_recent?
          # user won't be able to submit this story as new, so just redirect
          # them to the previous story
          flash[:success] = "This URL has already been submitted recently."
          return redirect_to s.comments_url
        else
          # user will see a warning like with preview screen
          @story.already_posted_story = s
        end
      end

      if params[:title].present?
        @story.title = params[:title]
      end
    end
  end

  def preview
    # we don't allow the url to be changed, so we have to set it manually
    @story = Story.new(params[:story].reject{|k,v| k == "url" })
    @story.url = params[:story][:url]
    @story.user_id = @user.id
    @story.previewing = true

    @story.vote = 1
    @story.upvotes = 1

    @story.valid?

    @story.seen_previous = true

    return render :action => "new", :layout => false
  end

  def show
    @story = Story.where(:short_id => params[:id]).first!

    if @story.can_be_seen_by_user?(@user)
      @title = @story.title
    else
      @title = "[Story removed]"
    end

    @short_url = @story.short_id_url

    @comments = @story.comments.includes(:user).arrange_for_user(@user)

    respond_to do |format|
      format.html {
        @comment = @story.comments.build

        load_user_votes

        render :action => "show"
      }
      format.json {
        render :json => @story.as_json(:with_comments => @comments)
      }
    end
  end

  def show_comment
    @story = Story.where(:short_id => params[:id]).first!

    @title = @story.title

    @showing_comment = Comment.where(:short_id => params[:comment_short_id]).first

    if !@showing_comment
      flash[:error] = "Could not find comment.  It may have been deleted."
      return redirect_to @story.comments_url
    end

    @comments = @story.comments
    if @showing_comment.thread_id
      @comments = @comments.where(:thread_id => @showing_comment.thread_id)
    end
    @comments = @comments.includes(:user).arrange_for_user(@user)

    @comments.each do |c,x|
      if c.id == @showing_comment.id
        c.highlighted = true
        break
      end
    end

    @comment = @story.comments.build

    load_user_votes

    render :action => "show"
  end

  def undelete
    if !(@story.is_editable_by_user?(@user) &&
    @story.is_undeletable_by_user?(@user))
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @story.is_expired = false
    @story.editor_user_id = @user.id
    @story.save(:validate => false)

    redirect_to @story.comments_url
  end

  def update
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @story.is_expired = false
    @story.editor_user_id = @user.id

    @story.attributes = params[:story].except(:url)
    if @story.url_is_editable_by_user?(@user)
      @story.url = params[:story][:url]
    end

    if @story.save
      return redirect_to @story.comments_url
    else
      return render :action => "edit"
    end
  end

  def unvote
    if !(story = find_story)
      return render :text => "can't find story", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, story,
      nil, @user.id, nil)

    render :text => "ok"
  end

  def upvote
    if !(story = find_story)
      return render :text => "can't find story", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, story,
      nil, @user.id, nil)

    render :text => "ok"
  end

  def downvote
    if !(story = find_story)
      return render :text => "can't find story", :status => 400
    end

    if !Vote::STORY_REASONS[params[:reason]]
      return render :text => "invalid reason", :status => 400
    end

    if !@user.can_downvote?
      return render :text => "not permitted to downvote", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story,
      nil, @user.id, params[:reason])

    render :text => "ok"
  end

private

  def find_story
    Story.where(:short_id => params[:story_id]).first
  end

  def find_user_story
    if @user.is_moderator?
      @story = Story.where(:short_id => params[:story_id] || params[:id]).first
    else
      @story = Story.where(:user_id => @user.id, :short_id =>
        (params[:story_id] || params[:id])).first
    end

    if !@story
      flash[:error] = "Could not find story or you are not authorized " <<
        "to manage it."
      redirect_to "/"
      return false
    end
  end

  def load_user_votes
    if @user
      if v = Vote.where(:user_id => @user.id, :story_id => @story.id,
      :comment_id => nil).first
        @story.vote = v.vote
      end

      @votes = Vote.comment_votes_by_user_for_story_hash(@user.id, @story.id)
      @comments.each do |c|
        if @votes[c.id]
          c.current_vote = @votes[c.id]
        end
      end
    end
  end
end
