# typed: false

class InboxController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_page, only: [:all]
  after_action :update_read_at, only: [:all, :unread]

  def index
    if @user.inbox_count > 0
      redirect_to inbox_unread_path
    else
      redirect_to inbox_all_path
    end
  end

  def all
    notifications_per_page = 25

    @notifications = @user
      .notifications
      .offset((@page - 1) * notifications_per_page)
      .limit(notifications_per_page)
      .order(created_at: :desc)
      .preload(user: [:hidings, :votes], notifiable: {story: [:tags, :user], user: [:comments], author: [], parent_comment: []})
    apply_current_vote

    @has_more = @user.notifications.count > (@page * notifications_per_page)

    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def unread
    @notifications = @user
      .notifications
      .where(read_at: nil)
      .order(created_at: :desc)
      .preload(user: [:hidings, :votes], notifiable: {story: [:tags, :user], user: [:comments], author: [], parent_comment: []})
    apply_current_vote

    respond_to do |format|
      format.html { render :all }
      format.json { render json: @notifications }
    end
  end

  private

  def update_read_at
    @notifications.where(read_at: nil).touch_all(:read_at)
  end

  def set_page
    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2**32)
      raise ActionController::RoutingError.new("page out of bounds")
    end
  end

  def apply_current_vote
    comment_notifications = @notifications.filter { |n| n.notifiable_type == "Comment" }.map(&:notifiable)
    comment_notifications = CommentVoteHydrator.new(comment_notifications, @user)
  end
end
