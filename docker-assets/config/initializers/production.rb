class << Rails.application
  def domain
    ENV["LOBSTER_HOSTNAME"]
  end

  def name
    ENV["LOBSTER_SITE_NAME"]
  end
end

Rails.application.routes.default_url_options[:host] = Rails.application.domain
