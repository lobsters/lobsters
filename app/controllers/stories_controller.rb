# typed: false

class StoriesController < ApplicationController
  include StoryFinder

  caches_page :show, if: CACHE_PAGE

  before_action :require_logged_in_user_or_400,
    only: [:upvote, :flag, :unvote, :hide, :unhide, :preview, :save, :unsave]
  before_action :require_logged_in_user,
    only: [:destroy, :create, :edit, :fetch_url_attributes, :new]
  before_action :verify_user_can_submit_stories, only: [:new, :create]
  before_action :find_user_story, only: [:destroy, :edit, :undelete, :update]
  around_action :track_story_reads, only: [:show], if: -> { @user.present? }
  before_action :show_title_h1, only: [:new, :edit]

  def create
    @title = "Submit Story"

    @story = Story.new(user: @user)
    update_story_attributes

    if @story.is_resubmit?
      @comment = @story.comments.new(user: @user)
      @comment.comment = params[:comment]
      @comment.hat = @user.wearable_hats.find_by(short_id: params[:hat_id])
    end

    if @story.valid? &&
        !@story.already_posted_recently? &&
        (!@story.is_resubmit? || @comment.valid?)

      Story.transaction do
        if @story.save && (!@story.is_resubmit? || @comment.save)
          ReadRibbon.where(user: @user, story: @story).first_or_create!
          redirect_to @story.comments_path
        else
          raise ActiveRecord::Rollback
        end
      end
      return if @story.persisted? # can't return out of transaction block
    end

    render action: "new"
  end

  def destroy
    if !@story.is_editable_by_user?(@user) && !@user.is_moderator?
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    update_story_attributes
    @story.is_deleted = true
    @story.editor = @user

    if @story.save
      Keystore.increment_value_for("user:#{@story.user.id}:stories_deleted")
      Mastodon.delete_post(@story)
    end

    redirect_to @story.comments_path
  end

  def edit
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @title = "Edit Story"
  end

  def fetch_url_attributes
    s = Story.new
    s.fetching_ip = request.remote_ip
    s.url = params[:fetch_url]

    render json: s.fetched_attributes
  end

  def new
    @title = "Submit Story"

    @story = Story.new(user_id: @user.id)
    @story.fetching_ip = request.remote_ip

    if params[:url].present?
      @story.url = params[:url]
      sattrs = @story.fetched_attributes

      if sattrs[:url].present? && @story.url != sattrs[:url]
        flash.now[:notice] = "Note: URL has been changed to fetched " \
          "canonicalized version"
        @story.url = sattrs[:url]
      end

      if @story.already_posted_recently?
        # user won't be able to submit this story as new, so just redirect
        # them to the previous story
        flash[:success] = "This URL has already been submitted recently."
        return redirect_to @story.most_recent_similar.comments_path
      end

      if @story.is_resubmit?
        @comment = @story.comments.new(user: @user)
        @comment.comment = params[:comment]
        @comment.hat = @user.wearable_hats.find_by(short_id: params[:hat_id])
      end

      # ignore what the user brought unless we need it as a fallback
      @story.title = sattrs[:title]
      if @story.title.blank? && params[:title].present?
        @story.title = params[:title]
      end
    end
  end

  def preview
    @story = Story.new
    update_story_attributes
    @story.user_id = @user.id
    @story.previewing = true

    @story.current_vote = Vote.new(vote: 1)
    @story.score = 1

    @story.valid?

    render action: "new", layout: false
  end

  def show
    # @story was already loaded by track_story_reads for logged-in users
    @story ||= Story.where(short_id: params[:id]).first!
    if @story.merged_into_story
      respond_to do |format|
        format.html {
          flash[:success] = "\"#{@story.title}\" has been merged into this story."
          return redirect_to @story.merged_into_story.comments_path
        }
        format.json {
          return redirect_to(story_path(@story.merged_into_story, format: :json))
        }
      end
    end

    # if asking with a title and it's been edited, 302
    if params[:title] && params[:title] != @story.title_as_url
      return redirect_to(@story.comments_path)
    end

    if @story.is_gone?
      @moderation = Moderation
        .where(story: @story, comment: nil)
        .where("action LIKE '%deleted story%'")
        .order(id: :desc)
        .first
    end
    if !@story.can_be_seen_by_user?(@user)
      respond_to do |format|
        format.html { return render action: "_missing", status: 404, locals: {story: @story, moderation: @moderation} }
        format.json { raise ActiveRecord::RecordNotFound }
      end
    end

    @user.try(:clear_unread_replies!)
    @comments = Comment.story_threads(@story).for_presentation

    @title = @story.title
    @short_url = @story.short_id_url

    respond_to do |format|
      format.html {
        @comment = @story.comments.build

        @meta_tags = {
          "twitter:card" => "summary",
          "twitter:site" => "@lobsters",
          "twitter:title" => @story.title,
          "twitter:description" => @story.comments_count.to_s + " " +
            "comment".pluralize(@story.comments_count),
          "twitter:image" => Rails.application.root_url +
            "touch-icon-144.png"
        }

        if @story.user.mastodon_username.present?
          @meta_tags["twitter:creator"] = @story.user.mastodon_acct
        end

        load_user_votes

        render action: "show"
      }
      format.json {
        @comments = @comments.includes(:parent_comment)
        render json: @story.as_json(with_comments: @comments)
      }
    end
  end

  def undelete
    if !(@story.is_editable_by_user?(@user) &&
    @story.is_undeletable_by_user?(@user))
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    update_story_attributes
    @story.is_deleted = false
    @story.editor = @user

    if @story.save
      Keystore.increment_value_for("user:#{@story.user.id}:stories_deleted", -1)
    end

    redirect_to @story.comments_path
  end

  def update
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @story.last_edited_at = Time.current
    @story.is_deleted = false
    @story.editor = @user
    update_story_attributes

    if @story.save
      redirect_to @story.comments_path
    else
      render action: "edit"
    end
  end

  def unvote
    if !(story = find_story) || story.is_gone?
      return render plain: "can't find story", status: 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      0, story.id, nil, @user.id, nil
    )

    render plain: "ok"
  end

  def upvote
    if !(story = find_story) || story.is_gone?
      return render plain: "can't find story", status: 400
    end

    if story.merged_into_story
      return render plain: "story has been merged", status: 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      1, story.id, nil, @user.id, nil
    )

    render plain: "ok"
  end

  def flag
    if !(story = find_story) || story.is_gone?
      return render plain: "can't find story", status: 400
    end

    if !Vote::STORY_REASONS[params[:reason]]
      return render plain: "invalid reason", status: 400
    end

    if !@user.can_flag?(story)
      return render plain: "not permitted to flag", status: 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(
      -1, story.id, nil, @user.id, params[:reason]
    )

    render plain: "ok"
  end

  def hide
    if !(story = find_story)
      return render plain: "can't find story", status: 400
    end

    if story.merged_into_story
      return render plain: "story has been merged", status: 400
    end

    HiddenStory.hide_story_for_user(story, @user)

    render plain: "ok"
  end

  def unhide
    if !(story = find_story)
      return render plain: "can't find story", status: 400
    end

    HiddenStory.unhide_story_for_user(story, @user)

    render plain: "ok"
  end

  def save
    if !(story = find_story)
      return render plain: "can't find story", status: 400
    end

    if story.merged_into_story
      return render plain: "story has been merged", status: 400
    end

    SavedStory.save_story_for_user(story.id, @user.id)

    render plain: "ok"
  end

  def unsave
    if !(story = find_story)
      return render plain: "can't find story", status: 400
    end

    SavedStory.where(user_id: @user.id, story_id: story.id).delete_all

    render plain: "ok"
  end

  def check_url_dupe
    raise ActionController::ParameterMissing.new("No URL") if params.dig(:story, :url).blank?
    @story = Story.new(user: @user)
    update_story_attributes
    @story.already_posted_recently?

    respond_to do |format|
      linking_comments = Link.recently_linked_from_comments(@story.url)
      format.html {
        return render partial: "stories/form_errors", layout: false,
          content_type: "text/html", locals: {
            linking_comments: linking_comments,
            story: @story
          }
      }
      # json: https://github.com/lobsters/lobsters/pull/555
      format.json {
        similar_stories = @story.public_similar_stories(@user).map(&:as_json)
        render json: @story.as_json.merge(similar_stories: similar_stories)
      }
    end
  end

  def disown
    if !((story = find_story) && story.disownable_by_user?(@user))
      return render plain: "can't find story", status: 400
    end

    InactiveUser.disown! story

    if request.xhr?
      @story = find_story
      @comments = Comment.story_threads(@story).for_presentation

      load_user_votes

      render partial: "listdetail", layout: false, content_type: "text/html", locals: {story: @story, single_story: true}
    else
      redirect_to story.short_id_path
    end
  end

  private

  def story_params
    ps = params.require(:story).permit(:title, :url, :description, :user_is_author, :user_is_following, tags: [])
    ps[:tags] = Tag.where(tag: ps[:tags] || @story.tags.map(&:tag), active: true)
    ps
  end

  def update_story_attributes
    @story.tags_was = @story.tags.to_a
    @story.attributes = if @story.url_is_editable_by_user?(@user)
      story_params
    else
      story_params.except(:url)
    end
  end

  def find_user_story
    @story = if @user.is_moderator?
      Story.where(short_id: params[:story_id] || params[:id]).first
    else
      Story.where(user_id: @user.id, short_id: params[:story_id] || params[:id]).first
    end

    if !@story
      flash[:error] = "Could not find story or you are not authorized " \
        "to manage it."
      redirect_to "/"
      false
    end
  end

  def load_user_votes
    if @user
      @story.current_vote = Vote.find_by(user: @user, story: @story, comment: nil)

      @story.is_hidden_by_cur_user = @story.is_hidden_by_user?(@user)
      @story.is_saved_by_cur_user = @story.is_saved_by_user?(@user)

      @votes = Vote.comment_votes_by_user_for_story_hash(
        @user.id, @story.merged_stories.ids.push(@story.id)
      )
      vote_summaries = Vote.comment_vote_summaries(@comments.map(&:id))
      @comments.each do |c|
        c.current_vote = @votes[c.id]
        c.vote_summary = vote_summaries[c.id]
      end
    end
  end

  def verify_user_can_submit_stories
    if !@user.can_submit_stories?
      flash[:error] = "You are not allowed to submit new stories."
      redirect_to "/"
    end
  end

  def track_story_reads
    @story = Story.where(short_id: params[:id]).first!
    @ribbon = ReadRibbon.where(user: @user, story: @story).first_or_initialize
    yield
    @ribbon.bump
  end
end
