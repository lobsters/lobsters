# typed: false

require "etc"

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") {
  if ENV.fetch("RAILS_ENV") == "production"
    10
  else
    3
  end
}
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
# port        ENV.fetch("PORT") { 3000 }
# bind 'tcp://127.0.0.1:3000'

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") {
  if ENV.fetch("RAILS_ENV") == "production"
    "/home/deploy/lobsters/shared/tmp/pids/puma.pid"
  else
    "tmp/puma.pid"
  end
}

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
workers ENV.fetch("PUMA_WORKERS") {
  if ENV.fetch("RAILS_ENV") == "production"
    Etc.nprocessors
  else
    2
  end
}

worker_boot_timeout 180

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
if ENV.fetch("RAILS_ENV") == "production"
  prune_bundler
  preload_app!
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
