class StoriesController < ApplicationController
  before_filter :require_logged_in_user_or_400,
    :only => [ :upvote, :downvote, :unvote, :hide, :unhide, :preview ]
  before_filter :require_logged_in_user, :only => [ :destroy, :create, :edit,
    :fetch_url_attributes, :new, :suggest ]
  before_filter :verify_user_can_submit_stories, :only => [ :new, :create ]
  before_filter :find_user_story, :only => [ :destroy, :edit, :undelete,
    :update ]
  before_filter :find_story!, :only => [ :suggest, :submit_suggestions ]
 
  around_action :track_story_reads, only: [ :show ], if: -> { @user.present? }
  
  def create
    @title = I18n.t 'controllers.stories_controller.submitstorytitle'
    @cur_url = "/stories/new"

    @story = Story.new(story_params)
    @story.user_id = @user.id

    if @story.valid? && !(@story.already_posted_story && !@story.seen_previous)
      if @story.save
        Countinual.count!("#{Rails.application.shortname}.stories.submitted",
          "+1")

        return redirect_to @story.comments_path
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
    @story.editor = @user

    if params[:reason].present? && @story.user_id != @user.id
      @story.moderation_reason = params[:reason]
    end

    @story.save(:validate => false)

    redirect_to @story.comments_path
  end

  def edit
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @title = I18n.t 'controllers.stories_controller.submitstorytitle'

    if @story.merged_into_story
      @story.merge_story_short_id = @story.merged_into_story.short_id
    end
  end

  def fetch_url_attributes
    s = Story.new
    s.fetching_ip = request.remote_ip
    s.url = params[:fetch_url]

    return render :json => s.fetched_attributes
  end

  def new
    @title = I18n.t 'controllers.stories_controller.submitstorytitle'
    @cur_url = "/stories/new"

    @story = Story.new
    @story.fetching_ip = request.remote_ip

    if params[:url].present?
      @story.url = params[:url]

      sattrs = @story.fetched_attributes

      if sattrs[:url].present? && @story.url != sattrs[:url]
        flash.now[:notice] = I18n.t 'controllers.stories_controller.flashcanonicalversion'
        @story.url = sattrs[:url]
      end

      if s = Story.find_similar_by_url(@story.url)
        if s.is_recent?
          # user won't be able to submit this story as new, so just redirect
          # them to the previous story
          flash[:success] = I18n.t 'controllers.stories_controller.flashalreadyposted'
          return redirect_to s.comments_path
        else
          # user will see a warning like with preview screen
          @story.already_posted_story = s
        end
      end

      # ignore what the user brought unless we need it as a fallback
      @story.title = sattrs[:title]
      if !@story.title.present? && params[:title].present?
        @story.title = params[:title]
      end
    end
  end

  def preview
    @story = Story.new(story_params)
    @story.user_id = @user.id
    @story.previewing = true
    @story.created_at = DateTime.now

    @story.vote = Vote.new(:vote => 1)
    @story.upvotes = 1

    @story.valid?

    @story.seen_previous = true

    return render :action => "new", :layout => false
  end

  def show
    @story = Story.where(:short_id => params[:id]).first!

    if @story.merged_into_story
      flash[:success] = I18n.t('controllers.stories_controller.flashmergedinto', :mergedstory => "#{@story.title}")
      return redirect_to @story.merged_into_story.comments_path
    end

    if !@story.can_be_seen_by_user?(@user)
      raise ActionController::RoutingError.new("story gone")
    end

    @title = @story.title
    @short_url = @story.short_id_url

    @comments = @story.merged_comments.includes(:user, :story, :hat,
      :votes => :user).arrange_for_user(@user)

    respond_to do |format|
      format.html {
        @comment = @story.comments.build

        @meta_tags = {
          "twitter:card" => "summary",
          "twitter:site" => "@lobsters",
          "twitter:title" => @story.title,
          "twitter:description" => "#{@story.comments_count} comment" <<
            "#{@story.comments_count == 1 ? "" : "s"}",
          "twitter:image" => Rails.application.root_url +
            "apple-touch-icon-144.png",
        }

        if @story.user.twitter_username.present?
          @meta_tags["twitter:creator"] = "@" + @story.user.twitter_username
        end

        load_user_votes

        render :action => "show"
      }
      format.json {
        render :json => @story.as_json(:with_comments => @comments)
      }
    end
  end

  def suggest
    if !@story.can_have_suggestions_from_user?(@user)
      flash[:error] = I18n.t 'controllers.stories_controller.flashnotallowedsuggestion'
      return redirect_to @story.comments_path
    end

    if (st = @story.suggested_taggings.where(:user_id => @user.id)).any?
      @story.tags_a = st.map{|st| st.tag.tag }
    end
    if tt = @story.suggested_titles.where(:user_id => @user.id).first
      @story.title = tt.title
    end
  end

  def submit_suggestions
    if !@story.can_have_suggestions_from_user?(@user)
      flash[:error] = I18n.t 'controllers.stories_controller.flashnotallowedsuggestion'
      return redirect_to @story.comments_path
    end

    ostory = @story.dup

    @story.title = params[:story][:title]
    if @story.valid?
      dsug = false
      if @story.title != ostory.title
        @story.save_suggested_title_for_user!(@story.title, @user)
        dsug = true
      end

      sugtags = params[:story][:tags_a].reject{|t| t.to_s.strip == "" }.sort
      if @story.tags_a.sort != sugtags
        @story.save_suggested_tags_a_for_user!(sugtags, @user)
        dsug = true
      end

      if dsug
        ostory = @story.reload
        flash[:success] = I18n.t 'controllers.stories_controller.flashallowedsuggestion'
      end
      redirect_to ostory.comments_path
    else
      render :action => "suggest"
    end
  end

  def undelete
    if !(@story.is_editable_by_user?(@user) &&
    @story.is_undeletable_by_user?(@user))
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @story.is_expired = false
    @story.editor = @user
    @story.save(:validate => false)

    redirect_to @story.comments_path
  end

  def update
    if !@story.is_editable_by_user?(@user)
      flash[:error] = "You cannot edit that story."
      return redirect_to "/"
    end

    @story.is_expired = false
    @story.editor = @user

    if @story.url_is_editable_by_user?(@user)
      @story.attributes = story_params
    else
      @story.attributes = story_params.except(:url)
    end

    if @story.save
      return redirect_to @story.comments_path
    else
      return render :action => "edit"
    end
  end

  def unvote
    if !(story = find_story)
      return render :text => "can't find story", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(0, story.id,
      nil, @user.id, nil)

    render :text => "ok"
  end

  def upvote
    if !(story = find_story)
      return render :text => "can't find story", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(1, story.id,
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

    if !@user.can_downvote?(story)
      return render :text => "not permitted to downvote", :status => 400
    end

    Vote.vote_thusly_on_story_or_comment_for_user_because(-1, story.id,
      nil, @user.id, params[:reason])

    render :text => "ok"
  end

  def hide
    if !(story = find_story)
      return render :text => "can't find story", :status => 400
    end

    HiddenStory.hide_story_for_user(story.id, @user.id)

    ReadRibbon.hide_replies_for(story.id, @user.id)
    render :text => "ok"
  end

  def unhide
    if !(story = find_story)
      return render :text => "can't find story", :status => 400
    end

    HiddenStory.where(:user_id => @user.id, :story_id => story.id).delete_all

    render :text => "ok"
  end

private

  def story_params
    p = params.require(:story).permit(
      :title, :url, :description, :moderation_reason, :seen_previous,
      :merge_story_short_id, :is_unavailable, :user_is_author, :tags_a => [],
    )

    if @user.is_moderator?
      p
    else
      p.except(:moderation_reason, :merge_story_short_id, :is_unavailable)
    end
  end

  def find_story
    story = Story.where(:short_id => params[:story_id]).first
    if @user && story
      story.vote = Vote.where(:user_id => @user.id,
        :story_id => story.id, :comment_id => nil).first.try(:vote)
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
        @story.vote = { :vote => v.vote, :reason => v.reason }
      end

      @story.is_hidden_by_cur_user = @story.is_hidden_by_user?(@user)

      @votes = Vote.comment_votes_by_user_for_story_hash(@user.id, @story.id)
      @comments.each do |c|
        if @votes[c.id]
          c.current_vote = @votes[c.id]
        end
      end
    end
  end

  def verify_user_can_submit_stories
    if !@user.can_submit_stories?
      flash[:error] = "You are not allowed to submit new stories."
      return redirect_to "/"
    end
  end
  def track_story_reads
    story = Story.where(short_id: params[:id]).first!
    @ribbon = ReadRibbon.where(user_id: @user.id, story_id: story.id).first_or_create
    yield
    @ribbon.updated_at = Time.now
    @ribbon.save
  end
end
