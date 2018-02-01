require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lobsters
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    #config.autoload_paths += %W(#{config.root}/extras)

    # Eager load everything in extras/
    config.eager_load_paths << Rails.root.join("extras").to_s

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Raise an exception when using mass assignment with unpermitted attributes
    config.action_controller.action_on_unpermitted_parameters = :raise

    # config.active_record.raise_in_transactional_callbacks = true

    config.cache_store = :file_store, "#{config.root}/tmp/cache/"

    config.exceptions_app = self.routes

    config.after_initialize do
      require "#{Rails.root}/lib/monkey.rb"
    end
  end
end

# disable yaml/xml/whatever input parsing
silence_warnings do
  ActionDispatch::ParamsParser::DEFAULT_PARSERS = {}
end

# define site name and domain to be used globally, should be overridden in a
# local file such as config/initializers/production.rb
class << Rails.application
  def allow_invitation_requests?
    true
  end

  def domain
    "example.com"
  end

  def name
    "Example News"
  end

  # to force everyone to be considered logged-out (without destroying
  # sessions) and refuse new logins
  def read_only?
    false
  end

  def root_url
    Rails.application.routes.url_helpers.root_url({
      :host => Rails.application.domain,
      :protocol => Rails.application.ssl? ? "https" : "http",
    })
  end

  # used as mailing list prefix, cannot have spaces
  def shortname
    name.downcase.gsub(/[^a-z]/, "")
  end

  # whether absolute URLs should include https (does not require that
  # config.force_ssl be on)
  def ssl?
    true
  end
end
