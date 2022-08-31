require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lobsters
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

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

    config.skip_yarn = true

    config.after_initialize do
      require "#{Rails.root}/lib/monkey.rb"
      require "#{Rails.root}/lib/time_series.rb"
    end

    config.generators do |g|
      g.factory_bot false
    end

    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # activerecord-typedstore needs:
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]

    # rails stop putting js on everything
    config.action_view.form_with_generates_remote_forms = false
  end
end

# disable yaml/xml/whatever input parsing
silence_warnings do
  ActionDispatch::Http::Parameters::DEFAULT_PARSERS = {}.freeze
end

# site-wide settings
class << Rails.application
  def allow_invitation_requests?
    false
  end

  def allow_new_users_to_invite?
    false
  end

  def open_signups?
    ENV["OPEN_SIGNUPS"] == "true"
  end

  def domain
    "lobste.rs"
  end

  def name
    "Lobsters"
  end

  # to force everyone to be considered logged-out (without destroying
  # sessions) and refuse new logins
  def read_only?
    false
  end

  def root_url
    Rails.application.routes.url_helpers.root_url(
      :host => Rails.application.domain,
      :protocol => Rails.application.ssl? ? "https" : "http",
    )
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
