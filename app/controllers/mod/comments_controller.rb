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
    Comment.find_by(short_id: params[:id])
  end
end
