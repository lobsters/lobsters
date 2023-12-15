# typed: false

require "etc"

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port        ENV.fetch("PORT") { 3000 }
# bind 'tcp://127.0.0.1:3000'

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") {
  if ENV.fetch("RAILS_ENV") == "production"
    "/srv/lobste.rs/run/puma.pid"
  else
    "tmp/puma.pid"
  end
}

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
workers ENV.fetch("PUMA_WORKERS") { 4 }

# In prod we run dozens of workers on a 4 core cpu. Puma starts all of them at
# the same time, pinning the CPU until the box is unresponsive. Where one
# worker takes 5-6.5s to start, starting 30 at the same time takes 90s for any
# to start so we throw a lot of 502s.  This hook runs before the app boots and
# sleeps a variable period to give other workers a chance to start.
worker_boot_duration = 7 # seconds, conservatively
# workers are numbered from zero, so:
# (0..11).map {|i| (i / 3.0).floor } => [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3]
def sleep_for_index index, worker_boot_duration
  workers_to_start_at_a_time = Etc.nprocessors - 1 # leave one open for serving
  (index / workers_to_start_at_a_time.to_f).floor * worker_boot_duration
end
last_index = (ENV.fetch("PUMA_WORKERS") { 4 }).to_i - 1
worker_boot_timeout sleep_for_index(last_index, worker_boot_duration) + worker_boot_duration * 3
on_worker_boot { |index| sleep sleep_for_index(index, worker_boot_duration) }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
if ENV.fetch("RAILS_ENV") == "production"
  # bind "unix:///srv/lobste.rs/run/puma.sock"

  # phased restarts
  # https://github.com/puma/puma/blob/master/docs/restart.md
  prune_bundler

  # old hot restart config; will need ansible change to tell systemctl to restart instead of reload
  # preload_app!
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
