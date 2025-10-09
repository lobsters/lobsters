class Mod::CommentsController < Mod::ModController
  def destroy
    if !((comment = find_comment) && comment.is_deletable_by_user?(@user))
      return render plain: "can't find comment", status: 400
    end
    
    reason = params[:reason]
    comment.delete_by_moderator(@user, reason)    

    if request.xhr?    
      head :ok, x_location: request.referer || comments_path
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
      comment.current_reply = @user.ids_replied_to([comment.id])
    end

    comment
  end  
end
