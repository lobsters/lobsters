class CspController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user

  def violation_report
    Rails.logger.info(request.body.read)
    head :ok
  end
end
