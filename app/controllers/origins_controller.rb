class OriginsController < ApplicationController
  def for_domain
    @domain = Domain.find_by!(domain: params[:id])
    @origins = @domain.origins.order(identifier: :asc)
  end
end
