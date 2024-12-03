# typed: false

class StoriesController < ApplicationController
  caches_page :show, if: CACHE_PAGE

  before_action :require_logged_in_user_or_400,
    only: [:upvote, :flag, :unvote, :hide, :unhide, :preview, :save, :unsave]
  before_action :require_logged_in_user,
    only: [:destroy, :create, :edit, :fetch_url_attributes, :new, :suggest]
  before_action :verify_user_can_submit_stories, only: [:new, :create]
  before_action :find_user_story, only: [:destroy, :edit, :undelete, :update]
  before_action :find_story!, only: [:suggest, :submit_suggestions]
  around_action :track_story_reads, only: [:show], if: -> { @user.present? }
  before_action :show_title_h1, only: [:new, :edit, :suggest]

  def create
    @title = "Submit Story"

    @story = Story.new(user: @user)
    @story.attributes = story_params

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
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    update_story_attributes

    if @story.user_id != @user.id && @user.is_moderator? && @story.moderation_reason.blank?
      @story.errors.add(:moderation_reason, message: "is required")
      return render action: "edit"
    end

    @story.is_deleted = true
    @story.editor = @user

    if @story.save
      Keystore.increment_value_for("user:#{@story.user.id}:stories_deleted")
    end

    redirect_to @story.comments_path
  end

  def edit
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @title = "Edit Story"

    if @story.merged_into_story
      @story.merge_story_short_id = @story.merged_into_story.short_id
      User.update_counters @story.user_id, karma: (@story.votes.count * -2)
    end
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
    @story = Story.new(story_params)
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
        .order("id desc")
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
            "apple-touch-icon-144.png"
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

  def suggest
    @title = "Suggest Story Changes"
    if !@story.can_have_suggestions_from_user?(@user)
      flash[:error] = "You are not allowed to offer suggestions on that story."
      return redirect_to @story.comments_path
    end

    if (suggested_tags = @story.suggested_taggings.where(user_id: @user.id)).any?
      @story.tags_a = suggested_tags.map { |st| st.tag.tag }
    end
    if (tt = @story.suggested_titles.where(user_id: @user.id).first)
      @story.title = tt.title
    end
  end

  def submit_suggestions
    if !@story.can_have_suggestions_from_user?(@user)
      flash[:error] = "You are not allowed to offer suggestions on that story."
      return redirect_to @story.comments_path
    end

    story_user = @story.user
    inappropriate_tags = Tag
      .where(tag: params[:story][:tags_a].reject { |t| t.to_s.blank? })
      .reject { |t| t.can_be_applied_by?(story_user) }
    if inappropriate_tags.length > 0
      tag_error = ""
      inappropriate_tags.each do |t|
        tag_error += if t.privileged?
          "User #{story_user.username} cannot apply tag #{t.tag} as they are not a " \
            "moderator so it has been removed from your suggestion.\n"
        elsif !t.permit_by_new_users?
          "User #{story_user.username} cannot apply tag #{t.tag} due to being a new " \
            "user so it has been removed from your suggestion.\n"
        else
          "User #{story_user.username} cannot apply tag #{t.tag} " \
            "so it has been removed from your suggestion.\n"
        end
      end
      tag_error += ""
      flash[:error] = tag_error
    end

    ostory = @story.dup

    @story.title = params[:story][:title]
    if @story.valid?
      dsug = false
      if @story.title != ostory.title
        @story.save_suggested_title_for_user!(@story.title, @user)
        dsug = true
      end

      sugtags = Tag
        .where(tag: params[:story][:tags_a].reject { |t| t.to_s.strip.blank? })
        .reject { |t| !t.can_be_applied_by?(story_user) }
        .map { |s| s.tag }
      if @story.tags_a.sort != sugtags.sort
        @story.save_suggested_tags_a_for_user!(sugtags, @user)
        dsug = true
      end

      if dsug
        ostory = @story.reload
        flash[:success] = "Your suggested changes have been noted."
      end
      redirect_to ostory.comments_path
    else
      render action: "suggest"
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
    raise ActionController::ParameterMissing.new("No URL") if story_params[:url].blank?
    @story = Story.new(user: @user)
    @story.attributes = story_params
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
    p = params.require(:story).permit(
      :title, :url, :description, :moderation_reason,
      :merge_story_short_id, :is_unavailable, :user_is_author, :user_is_following,
      tags_a: []
    )

    if @user&.is_moderator?
      p
    else
      p.except(:moderation_reason, :merge_story_short_id, :is_unavailable)
    end
  end

  def update_story_attributes
    @story.attributes = if @story.url_is_editable_by_user?(@user)
      story_params
    else
      story_params.except(:url)
    end
  end

  def find_story
    story = Story.find_by(short_id: params[:story_id])
    # convenience to use PK (from external queries) without generally permitting enumeration:
    story ||= Story.find(params[:id]) if @user&.is_admin?

    if @user && story
      story.current_vote = Vote.find_by(
        user: @user,
        story: story.id,
        comment: nil
      ).try(:vote)
    end

    story
  end

  def find_story!
    @story = find_story
    if !@story
      raise ActiveRecord::RecordNotFound
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
