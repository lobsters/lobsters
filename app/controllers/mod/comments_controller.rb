class Mod::CommentsController < Mod::ModController
  def destroy
    if !comment = find_comment
      return render plain: "can't find comment", status: 400
    end

    reason = params[:reason]
    comment.delete_by_moderator(@user, reason)

    if request.xhr?
      render partial: "comments/comment",
        layout: false,
        content_type: "text/html",
        locals: {comment:}
    else
      redirect_to comment_path(comment)
    end
  end

  private

  def find_comment
    Comment.find_by(short_id: params[:id])
  end
end
