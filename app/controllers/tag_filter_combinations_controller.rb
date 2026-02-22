# typed: false

class TagFilterCombinationsController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_combination, only: [:destroy]

  def index
    @combinations = @user.tag_filter_combinations.includes(:tags)
    @categories = Category.includes(:tags)
      .where(tags: {active: true})
      .order([categories: {category: :asc}, tags: {tag: :asc}])
    @story_counts = Tagging.group(:tag_id).count
  end

  def create
    @combination = @user.tag_filter_combinations.build
    tag_ids = params[:tag_ids].to_a.map(&:to_i).uniq

    if tag_ids.size < 2
      flash[:error] = "Select at least 2 tags"
      redirect_to tag_filter_combinations_path
      return
    end

    sorted_ids = tag_ids.sort
    # tags association is ordered by id, so no sort needed on existing
    existing = @user.tag_filter_combinations.includes(:tags).any? { |c|
      c.tags.map(&:id) == sorted_ids
    }
    if existing
      flash[:error] = "You already have this tag combination filtered"
      redirect_to tag_filter_combinations_path
      return
    end

    @combination.tags = Tag.where(id: tag_ids)

    if @combination.save
      flash[:success] = "Tag combination filter added"
    else
      flash[:error] = @combination.errors.full_messages.join(", ")
    end

    redirect_to tag_filter_combinations_path
  end

  def destroy
    @combination.destroy
    flash[:success] = "Tag combination filter removed"
    redirect_to tag_filter_combinations_path
  end

  private

  def set_combination
    @combination = @user.tag_filter_combinations.find(params[:id])
  end
end
