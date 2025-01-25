# typed: false

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Lobsters
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets custom_cops tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "Central Time (US & Canada)"

    config.eager_load_namespaces << I18n

    config.autoload_paths.push(
      "#{root}/extras",
      "#{root}/lib"
    )

    # Raise an exception when using mass assignment with unpermitted attributes
    config.action_controller.action_on_unpermitted_parameters = :raise

    # log where queries came from
    config.active_record.query_log_tags_enabled = true
    config.active_record.cache_query_log_tags = true

    config.cache_store = :file_store, "#{config.root}/tmp/cache/"
    config.active_support.cache_format_version = 7.0 # bump to 7.1 after 7.1 deploy fills caches

    config.exceptions_app = routes

    config.skip_yarn = true

    config.after_initialize do
      require Rails.root.join("lib/time_series.rb").to_s
    end

    config.generators do |g|
      g.factory_bot false
    end

    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # activerecord-typedstore needs:
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]

    # rails stop putting js on everything
    config.action_view.form_with_generates_remote_forms = false

    config.mission_control.jobs.base_controller_class = "JobsModController"
    config.mission_control.jobs.http_basic_auth_enabled = false
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
      host: Rails.application.domain,
      protocol: Rails.application.ssl? ? "https" : "http"
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

  # username of the admin account used to ban domains automatically (e.g., URL shorteners)
  def banned_domains_admin
    ENV["BANNED_DOMAINS_ADMIN"] || "pushcx"
  end
end
