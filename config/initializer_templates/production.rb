class << Rails.application
  def domain
    "whisk.com"
  end

  def name
    "whisk me away"
  end
end

Rails.application.routes.default_url_options[:host] = Rails.application.domain
