# typed: false

class ModerationsController < ApplicationController
  ENTRIES_PER_PAGE = 50

  before_action :show_title_h1

  def index
    @title = "Moderation Log"
    @moderators = ["(All)", "(Users)"] + User.moderators.map(&:username)

    @moderator = moderation_params.fetch("moderator", "(All)")
    @what = {
      stories: moderation_params.dig(:what, :stories),
      comments: moderation_params.dig(:what, :comments),
      tags: moderation_params.dig(:what, :tags),
      users: moderation_params.dig(:what, :users),
      domains: moderation_params.dig(:what, :domains),
      origins: moderation_params.dig(:what, :origins),
      categories: moderation_params.dig(:what, :categories)
    }
    @what.transform_values! { true } if @what.values.none?

    @moderations = Moderation.all.eager_load(:moderator,
      :story,
      {comment: [:story, :user]},
      :tag,
      :user,
      :domain,
      :origin,
      :category)

    # filter based on target
    @moderations = case @moderator
    when "(All)"
      @moderations
    when "(Users)"
      @moderations.where(is_from_suggestions: true)
    else
      @moderations.joins(:moderator).where(users: {username: @moderator})
    end

    # filter based on type of thing moderated
    @what.each do |type, checked|
      next if checked
      @moderations = @moderations.where("#{type.to_s.singularize}_id": nil)
    end

    # paginate
    @pages = helpers.page_count(@moderations.count, ENTRIES_PER_PAGE)
    @page = moderation_params.fetch(:page) { 1 }.to_i

    if @page <= 0 || @page > (2**32) || @page > @pages
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @moderations = @moderations
      .offset((@page - 1) * ENTRIES_PER_PAGE)
      .order("moderations.created_at desc")
      .limit(ENTRIES_PER_PAGE)
  end

  private

  def moderation_params
    @moderation_params ||= params.permit(:moderator, :page,
      what: %i[stories comments tags users domains origins categories])
  end
end
