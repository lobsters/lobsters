# typed: false

class HatsController < ApplicationController
  before_action :require_logged_in_user, except: [:index]
  before_action :show_title_h1
  before_action :find_hat!, only: [:doff, :doff_by_user, :edit, :update_in_place, :update_by_recreating]
  before_action :only_hat_user_or_moderator, only: [:edit, :update_in_place, :update_by_recreating, :doff, :doff_by_user]

  def index
    @title = "Hats"

    @hat_groups = {}

    Hat.active.includes(:user).find_each do |h|
      @hat_groups[h.hat] ||= []
      @hat_groups[h.hat].push h
    end
  end

  def doff
    @title = "Doffing a Hat"
  end

  def doff_by_user
    if params[:reason].blank?
      flash[:error] = "You must give a reason for the doffing."
      return redirect_to doff_hat_path(@hat)
    end

    @hat.doff_by_user_with_reason(@user, params[:reason])
    redirect_to @user
  end

  def edit
    @title = "Edit a Hat"
  end

  def update_in_place
    old_hat = @hat.hat
    new_hat = params[:hat][:hat]

    if @hat.update(hat: new_hat)
      m = Moderation.new
      m.user_id = @hat.user_id
      m.moderator_user_id = @hat.user_id
      m.action = "Renamed hat \"#{old_hat}\" to \"#{new_hat}\""
      m.save!

      redirect_to hats_url
    else
      flash[:error] = @hat.errors.full_messages.join(", ")
      redirect_to edit_hat_path(@hat)
    end
  end

  def update_by_recreating
    new_hat = params[:hat][:hat]

    replaced_hat = @hat.dup
    replaced_hat.hat = new_hat
    replaced_hat.doffed_at = nil

    if replaced_hat.save
      @hat.doff_by_user_with_reason(@user, "To replace with \"#{new_hat}\"")

      redirect_to hats_url
    else
      flash[:error] = replaced_hat.errors.full_messages.join(", ")
      redirect_to edit_hat_path(@hat)
    end
  end

  private

  def only_hat_user_or_moderator
    if @hat.user == @user || @user&.is_moderator?
      true
    else
      redirect_to @user
    end
  end

  def find_hat!
    @hat = if @user.is_moderator?
      Hat.find_by(short_id: params[:id])
    else
      @user.wearable_hats.find_by(short_id: params[:id])
    end
  end
end
