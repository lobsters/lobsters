# typed: false

require "fileutils"
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Prepare the ingress controller used to receive mail
  config.action_mailbox.ingress = :relay

  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Should default to true, but doesn't...
  config.assets.digest = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # I updated sprockets and every page raised 'The asset "application.css" is not present in the
  # asset pipeline.' And then I turned this on and everything was fine. The asset pipeline continues
  # to be a fiddly, unreliable mystery.
  config.assets.unknown_asset_fallback = true

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security (HSTS), and use secure cookies.
  config.force_ssl = true
  # expiration, preload, and subdomains for: https://hstspreload.org/
  config.ssl_options = {hsts: {expires: 63072000, preload: true, subdomains: true}}

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  config.assume_ssl = true

  # Info include generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Rails log goes to stdout for hatchbox UI and a file for grep.
  # https://hatchbox.relationkit.io/articles/61-accessing-your-server-logs-in-hatchbox
  config.logger = ActiveSupport::BroadcastLogger.new(
    ActiveSupport::Logger.new($stdout),
    ActiveSupport::Logger.new(Rails.root.join("log/rails.log"))
  )
  config.logger.formatter = config.log_formatter

  # see config/initializers/lograge.rb for json action logs
  config.lograge.enabled = true

  # SolidQueue log to stdout for hatchbox UI and a file for grep
  config.solid_queue.logger = ActiveSupport::BroadcastLogger.new(
    ActiveSupport::Logger.new($stdout),
    ActiveSupport::Logger.new(Rails.root.join("log/solid_queue.log"))
  )

  # Use a different cache store in production.
  config.cache_store = :solid_cache_store

  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = {database: {writing: :queue}}
  config.solid_queue.clear_finished_jobs_after = 90.days

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = {
    host: Rails.application.domain
  }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # cache full pages for logged-out visitors without tag filters
  config.action_controller.perform_caching = true
  config.action_controller.page_cache_directory = Rails.public_path.join("cache").to_s

  # why help timing attacks?
  config.middleware.delete(Rack::Runtime)

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.active_storage.service = :local
end

# disable some excessive logging in production
%w[render_template render_partial render_collection].each do |event|
  ActiveSupport::Notifications.unsubscribe "#{event}.action_view"
end
