class Mod::OriginsController < Mod::ModController
  before_action :find_or_initialize_origin, only: [:edit]

  def edit
    @title = "Edit Origin #{params[:identifier]}"
    @title_h1 = false
  end

  private

  def find_or_initialize_origin
    @origin = Origin.find_or_initialize_by identifier: params[:identifier]
  end
end
