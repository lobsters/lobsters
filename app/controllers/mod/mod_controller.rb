# This is the parent class of all controllers under /mod. Standardrb enforces this in
# CustomCops/InheritsModeratorController so that we can't forget the auth check.
class Mod::ModController < ApplicationController
  before_action :require_logged_in_moderator
  before_action :default_periods, :show_title_h1

  private

  def default_periods
    @periods ||= %w[1d 2d 3d 1w 1m]
  end

  def period(query)
    length = time_interval(params[:period] || default_periods.first)
    query.where("#{query.model.table_name}.created_at >=
      (NOW() - INTERVAL #{length[:dur]} #{length[:intv].upcase})")
  end
end
