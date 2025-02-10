# typed: false

class CommentsController < ApplicationController
  COMMENTS_PER_PAGE = 20

  caches_page :index, :threads, if: CACHE_PAGE

  before_action :require_logged_in_user_or_400,
    only: [:create, :reply, :upvote, :flag, :unvote, :update]
  before_action :require_logged_in_user, only: [:upvoted]
  before_action :show_title_h1

  # for rss feeds, load the user's tag filters if a token is passed
  before_action :find_user_from_rss_token, only: [:index]

  def create
    if !(story = Story.where(short_id: params[:story_id]).first) ||
        story.is_gone?
      return render plain: "can't find story", status: 400
    end

    comment = story.comments.build
    comment.comment = params[:comment].to_s
    comment.user = @user
    comment.hat = @user.wearable_hats.find_by(short_id: params[:hat_id])

    if params[:parent_comment_short_id].present?
      # includes parent story_id to ensure this comment's story_id matches
      comment.parent_comment =
        Comment.find_by(story_id: story.id, short_id: params[:parent_comment_short_id])
      if !comment.parent_comment
        return render json: {error: "invalid parent comment", status: 400}
      end
    end

    # sometimes on slow connections people resubmit; silently accept it
    if (already = Comment.find_by(user: comment.user,
      story: comment.story,
      parent_comment_id: comment.parent_comment_id,
      comment: comment.comment))
      render_created_comment(already)
      return
    end

    if params[:preview].blank? && comment.breaks_speed_limit?
      return render partial: "commentbox", layout: false,
        content_type: "text/html", locals: {comment: comment}
    end

    if comment.valid? && params[:preview].blank? && comment.save
      comment.current_vote = {vote: 1}
      comment.story.touch(:last_comment_at)
      # not using .touch because the :touch on the parent_comment association will already touch the
      # upated_at columns up the reply chain to the story once
      comment.parent_comment&.update_column(:last_reply_at, Time.current)
      render_created_comment(comment)
    else
      comment.score = 1
      comment.current_vote = {vote: 1}

      preview comment
    end
  end

  def show
    if !(comment = find_comment)
      return render plain: "can't find comment", status: 404
    end
    if !comment.is_editable_by_user?(@user)
      return redirect_to comment.path
    end

    render partial: "comment",
      layout: false,
      content_type: "text/html",
      locals: {
        comment: comment,
        show_tree_lines: params[:show_tree_lines]
      }
  end

  def show_short_id
    if !(comment = find_comment)
      return render plain: "can't find comment", status: 400
    end

    render json: comment.as_json
  end

  def redirect_from_short_id
    if (comment = find_comment)
      redirect_to comment.path
    else
      render plain: "can't find comment", status: 400
    end
  end

  def edit
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render plain: "can't find comment", status: 400
    end

    render partial: "commentbox", layout: false,
      content_type: "text/html", locals: {comment: comment}
  end

  def reply
    if !(parent_comment = find_comment)
      return render plain: "can't find comment", status: 400
    end

    story = parent_comment.story
    comment = story.comments.build
    comment.parent_comment = parent_comment
    comment.comment = params[:comment].to_s
    comment.user = @user

    if !parent_comment.depth_permits_reply?
      ModNote.tattle_on_max_depth_limit(@user, parent_comment)
      if request.xhr?
        render partial: "too_deep"
      else
        render "_too_deep"
      end
      return
    end

    if request.xhr?
      render partial: "commentbox", locals: {comment: comment, story: story}
    else
      parents = comment.parents.for_presentation

      parent_ids = parents.map(&:id)
      @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user&.id, parent_ids)
      summaries = Vote.comment_vote_summaries(parent_ids)
      parents.each do |c|
        c.current_vote = @votes[c.id]
        c.vote_summary = summaries[c.id]
      end
      render "_commentbox", locals: {
        comment: comment,
        story: story,
        parents: parents
      }
    end
  end

  def delete
    if !((comment = find_comment) && comment.is_deletable_by_user?(@user))
      return render plain: "can't find comment", status: 400
    end

    comment.delete_for_user(@user, params[:reason])

    render partial: "comment", layout: false,
      content_type: "text/html", locals: {comment: comment}
  end

  def undelete
    if !((comment = find_comment) && comment.is_undeletable_by_user?(@user))
      return render plain: "can't find comment", status: 400
    end

    comment.undelete_for_user(@user)

    render partial: "comment", layout: false,
      content_type: "text/html", locals: {comment: comment}
  end

  def disown
    if !((comment = find_comment) && comment.is_disownable_by_user?(@user))
      return render plain: "can't find comment", status: 400
    end

    InactiveUser.disown! comment

    if request.xhr?
      comment = find_comment
      show_story = ActiveModel::Type::Boolean.new.cast(params[:show_story])
      show_tree_lines = ActiveModel::Type::Boolean.new.cast(params[:show_tree_lines])

      render partial: "comment", locals: {comment: comment, show_story: show_story, show_tree_lines: show_tree_lines}
    else
      redirect_back fallback_location: root_path
    end
  end

  def update
    if !((comment = find_comment) && comment.is_editable_by_user?(@user))
      return render plain: "can't find comment", status: 400
    end

    comment.comment = params[:comment]
    comment.last_edited_at = Time.current
    comment.hat_id = nil
    comment.hat = @user.wearable_hats.find_by(short_id: params[:hat_id])

    if params[:preview].blank? && comment.save
      votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, [comment.id])
      comment.current_vote = votes[comment.id]
      comment.vote_summary = Vote.comment_vote_summaries([comment.id])[comment.id]
      # not using .touch because the :touch on the parent_comment association will already touch the
      # upated_at columns up the reply chain to the story once
      comment.parent_comment&.touch(:last_reply_at)

      render partial: "comments/comment",
        layout: false,
        content_type: "text/html",
        locals: {comment: comment, show_tree_lines: params[:show_tree_lines]}
    else
      comment.current_vote = {vote: 1}

      preview comment
    end
  end

  def unvote
    if !(comment = find_comment) || comment.is_gone?
      return render plain: "can't find comment", status: 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      0, comment.story_id, comment.id, @user.id, nil
    )

    render plain: "ok"
  end

  def upvote
    if !(comment = find_comment) || comment.is_gone?
      return render plain: "can't find comment", status: 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      1, comment.story_id, comment.id, @user.id, nil
    )

    render plain: "ok"
  end

  def flag
    if !(comment = find_comment) || comment.is_gone?
      return render plain: "can't find comment", status: 400
    end

    if !Vote::COMMENT_REASONS[params[:reason]]
      return render plain: "invalid reason", status: 400
    end

    if !@user.can_flag?(comment)
      return render plain: "not permitted to flag", status: 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      -1, comment.story_id, comment.id, @user.id, params[:reason]
    )

    render plain: "ok"
  end

  def index
    @rss_link ||= {
      title: "RSS 2.0 - Newest Comments",
      href: "/comments.rss" + (@user ? "?token=#{@user.rss_token}" : "")
    }

    @title = "Newest Comments"

    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2**32)
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @comments = Comment.accessible_to_user(@user)
      .not_on_story_hidden_by(@user)
      .order(id: :desc)
      .includes(:user, :hat, story: :user)
      .joins(:story).where.not(stories: {is_deleted: true})
      .limit(COMMENTS_PER_PAGE)
      .offset((@page - 1) * COMMENTS_PER_PAGE)

    comment_ids = @comments.map(&:id)
    @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user&.id, comment_ids)
    summaries = Vote.comment_vote_summaries(comment_ids)
    @comments.each do |c|
      c.current_vote = @votes[c.id]
      c.vote_summary = summaries[c.id]
    end

    respond_to do |format|
      format.html { render action: "index" }
      format.rss {
        if @user && params[:token].present?
          @title = "Private comments feed for #{@user.username}"
          render action: "index", layout: false
        else
          content = Rails.cache.fetch("comments.rss", expires_in: (60 * 2)) {
            render_to_string action: "index", layout: false
          }
          render plain: content, layout: false
        end
      }
    end
  end

  def upvoted
    @rss_link ||= {
      title: "RSS 2.0 - Newest Comments",
      href: upvoted_comments_path(format: :rss) + (@user ? "?token=#{@user.rss_token}" : "")
    }

    @title = "Upvoted Comments"
    @above = "saved/subnav"

    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2**32)
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @comments = Comment.accessible_to_user(@user)
      .where.not(user_id: @user.id)
      .order(id: :desc)
      .includes(:user, :hat, story: :user)
      .joins(:votes).where(votes: {user_id: @user.id, vote: 1})
      .joins(:story).where.not(stories: {is_deleted: true})
      .limit(COMMENTS_PER_PAGE)
      .offset((@page - 1) * COMMENTS_PER_PAGE)

    # TODO: respect hidden stories

    comment_ids = @comments.map(&:id)
    @votes = Vote.comment_votes_by_user_for_comment_ids_hash(@user.id, comment_ids)
    summaries = Vote.comment_vote_summaries(comment_ids)
    @comments.each do |c|
      c.current_vote = @votes[c.id]
      c.vote_summary = summaries[c.id]
    end

    respond_to do |format|
      format.html { render action: :index }
      format.rss {
        if @user && params[:token].present?
          @title = "Upvoted comments feed for #{@user.username}"
        end

        render action: "index", layout: false
      }
    end
  end

  def user_threads
    if params[:user]
      @showing_user = User.find_by!(username: params[:user])
      @title = "Threads for #{@showing_user.username}"
    elsif !@user
      return redirect_to active_path
    else
      @showing_user = @user
      @title = "Your Threads"
    end

    @threads = Comment.recent_threads(@showing_user)
      .accessible_to_user(@user)
      .merge(Story.not_deleted(@user))
      .for_presentation
      .joins(:story)

    if @user
      @user.clear_unread_replies!
      @votes = Vote.comment_votes_by_user_for_story_hash(@user.id, @threads.map(&:story_id).uniq)
      summaries = Vote.comment_vote_summaries(@threads.map(&:id))

      @threads.each do |c|
        c.current_vote = @votes[c.id]
        c.vote_summary = summaries[c.id]
      end
    end
  end

  private

  def find_comment
    comment = Comment.where(short_id: params[:id]).first
    # convenience to use PK (from external queries) without generally permitting enumeration:
    comment ||= Comment.find(params[:id]) if @user&.is_admin?

    if @user && comment
      comment.current_vote = Vote.where(user_id: @user.id,
        story_id: comment.story_id, comment_id: comment.id).first
      comment.vote_summary = Vote.comment_vote_summaries([comment.id])[comment.id]
    end

    comment
  end

  def preview(comment)
    comment.previewing = true
    comment.is_deleted = false # show normal preview for deleted comments

    render partial: "comments/commentbox",
      layout: false,
      content_type: "text/html",
      locals: {
        comment: comment,
        show_comment: comment,
        show_tree_lines: params[:show_tree_lines]
      }
  end

  def render_created_comment(comment)
    if request.xhr?
      render partial: "comments/postedreply", layout: false,
        content_type: "text/html", locals: {comment: comment}
    else
      redirect_to comment.path
    end
  end
end
