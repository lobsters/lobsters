# typed: false

class NotificationsController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_page, only: [:all]
  after_action :update_read_at

  def all
    notifications_per_page = 25

    @notifications = @user
      .notifications
      .offset((@page - 1) * notifications_per_page)
      .limit(notifications_per_page)
      .order(created_at: :desc)
      .preload(user: [:hidings, :votes], notifiable: {story: [:tags, :user], user: [:comments], author: [], parent_comment: []})

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

    respond_to do |format|
      format.html { render :all }
      format.json { render json: @notifications }
    end
  end

  private

  def update_read_at
    @notifications.touch_all(:read_at)
    message_ids = @notifications.of_messages.pluck(:notifiable_id)
    Message.where(id: message_ids).update_all(has_been_read: true)
  end

  def set_page
    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2**32)
      raise ActionController::RoutingError.new("page out of bounds")
    end
  end
end
