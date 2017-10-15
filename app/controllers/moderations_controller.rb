class ModerationsController < ApplicationController
  ENTRIES_PER_PAGE = 50

  def index
    @title = "Moderation Log"
    @moderators = ['(All)', '(Users)'] + User.moderators.map(&:username)

    @moderator = params.fetch('moderator', '(All)')
    @what = {
      :stories  => params.dig(:what, :stories),
      :comments => params.dig(:what, :comments),
      :users    => params.dig(:what, :users),
    }
    @what = { :stories => true, :comments => true, :users => true } if @what.values.none?

    @moderations = Moderation.all.eager_load(:moderator, :story, :comment, :user)

    # filter based on target
    @moderations = case @moderator
    when '(All)'
      @moderations
    when '(Users)'
      @moderations.where("is_from_suggestions = true")
    else
      @moderations.joins(:moderator).where(:users => { :username => @moderator })
    end

    # filter based on type of thing moderated
    @what.each do |type, checked|
      next if checked
      @moderations = @moderations.where("`moderations`.`#{type.to_s.singularize}_id` is null")
    end

    # paginate
    @pages = (@moderations.count / ENTRIES_PER_PAGE).ceil
    @page = params[:page].to_i
    if @page == 0
      @page = 1
    elsif @page < 0 || @page > (2 ** 32) || @page > @pages
      raise ActionController::RoutingError.new("page out of bounds")
    end

    @moderations = @moderations
                    .offset((@page - 1) * ENTRIES_PER_PAGE)
                    .order("moderations.id desc")
                    .limit(ENTRIES_PER_PAGE)
  end
end
