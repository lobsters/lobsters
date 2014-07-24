# define site name and domain to be used globally, can be overridden in
# config/initializers/production.rb
class << Rails.application
  def domain
    Lobsters::Config[:domain]
  end

  def name
    Lobsters::Config[:name]
  end
  
  def protocol
    Lobsters::Config[:protocol]
  end

  # used as mailing list prefix and countinual prefix, cannot have spaces
  def shortname
    name.downcase.gsub(/[^a-z]/, "")
  end
end

Rails.application.routes.default_url_options[:host] = Rails.application.domain
Rails.application.routes.default_url_options[:protocol] = Rails.application.protocol
