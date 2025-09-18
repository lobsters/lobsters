# typed: false

class Mod::ActivitiesController < Mod::ModController
  def index
    @title = "Mod Activity last 3 months"
    @mod_activities = ModActivity
      .with_item
      .where("mod_activities.created_at >= ?", 3.months.ago)
      .order(created_at: :desc)
  end
end
