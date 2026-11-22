class Mod::ModInboxController < Mod::ModController
  KINDS = %w[stories comments hotspots].freeze
  NOTIFICATIONS_PER_PAGE = 100

  before_action :set_page, only: [:all]
  before_action :set_kinds
  after_action :update_read_at, only: [:all, :unread]

  def index
    if @user.mod_inbox_count > 0
      redirect_to mod_inbox_unread_path
    else
      redirect_to mod_inbox_all_path
    end
  end

  def all
    @title = "Mod Inbox"
    @notifications = notifications
      .offset((@page - 1) * NOTIFICATIONS_PER_PAGE)
      .limit(NOTIFICATIONS_PER_PAGE)
    @has_more = notifications.count > (@page * NOTIFICATIONS_PER_PAGE)
    apply_current_vote
  end

  def unread
    @title = "Unread Mod Inbox"
    @notifications = notifications.unread
    apply_current_vote
    render :all
  end

  private

  def notifications
    kinds = []
    kinds << ModNotification.of_stories.flagged if @kinds.include?("stories")
    kinds << ModNotification.of_comments.flagged if @kinds.include?("comments")
    kinds << ModNotification.of_comments.hotspot if @kinds.include?("hotspots")

    @user.mod_notifications
      .merge(kinds.reduce(:or) || ModNotification.none)
      .order(created_at: :desc, id: :desc)
      .preload(notifiable: {user: [], hat: [], story: [:user, :tags], tags: [], hotspot_doc: [], votes: :user})
  end

  def apply_current_vote
    @comments = CommentVoteHydrator.new(@notifications.filter { it.notifiable_type == "Comment" }.map(&:notifiable), @user)
    @terms = HotspotTerm.order(weight: :desc).pluck(:term) if @kinds.include?("hotspots")
  end

  def update_read_at
    @notifications.where(read_at: nil).touch_all(:read_at)
  end

  def set_kinds
    @kinds = params.key?(:show) ? KINDS & Array(params[:show]) : KINDS
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
