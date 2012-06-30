class CommentsController < ApplicationController
  before_filter :require_logged_in_user_or_400,
    :only => [ :create, :preview, :upvote, :downvote, :unvote ]

  def create
    if !(story = Story.find_by_short_id(params[:story_id]))
      return render :text => "can't find story", :status => 400
    end

    comment = Comment.new
    comment.comment = params[:comment].to_s
    comment.story_id = story.id
    comment.user_id = @user.id

    if params[:parent_comment_short_id]
      if pc = Comment.find_by_story_id_and_short_id(story.id,
      params[:parent_comment_short_id])
        comment.parent_comment_id = pc.id
        comment.parent_comment_short_id = pc.short_id
      else
        return render :json => { :error => "invalid parent comment",
          :status => 400 }
      end
    end

    if comment.valid? && !params[:preview].present? && comment.save
      comment.current_vote = { :vote => 1 }

      render :partial => "stories/commentbox", :layout => false,
        :content_type => "text/html", :locals => { :story => story,
        :comment => Comment.new, :show_comment => comment }
    else
      comment.previewing = true
      comment.upvotes = 1
      comment.current_vote = { :vote => 1 }

      render :partial => "stories/commentbox", :layout => false,
        :content_type => "text/html", :locals => { :story => story,
        :comment => comment, :show_comment => comment }
    end
  end

  def preview
    params[:preview] = true
    return create
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
end
