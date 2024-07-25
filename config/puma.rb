# typed: false

require "etc"

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 4 }
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
# port        ENV.fetch("PORT") { 3000 }
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
workers ENV.fetch("PUMA_WORKERS") { 3 }

worker_boot_timeout 180

# https://github.com/Shopify/ruby/issues/556
on_first_worker = false
on_worker_boot do |worker_index|
  on_first_worker = worker_index == 0

  if on_first_worker
    require "objspace"
    GC.start
    File.open("/tmp/heap-boot.json", "w") do |f|
      ObjectSpace.dump_all(output: f)
    end
    if defined?(RubyVM::YJIT)
      Thread.new do
        loop do
          # rubocop doesn't know activesupport isn't available here
          # rubocop:disable Rails/TimeZone
          # File.write("/tmp/yjit-stats.txt", [Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L%z"), " ", RubyVM::YJIT.runtime_stats, " ", GC.stat, "\n"].join, mode: "a+")
          # rubocop:enable Rails/TimeZone
          sleep 300
        end
      end
    end
  end
end

heap_dumped = false
out_of_band do
  if on_first_worker && !heap_dumped
    if GC.stat(:heap_live_slots) > 500_000
      GC.start
      if GC.stat(:heap_live_slots) > 500_000
        heap_dumped = true
        File.open("/tmp/heap-bloated.json", "w") do |f|
          ObjectSpace.dump_all(output: f)
        end
      end
    end
  end
end

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
if ENV.fetch("RAILS_ENV") == "production"
  bind "unix:///srv/lobste.rs/run/puma.sock"

  # phased restarts
  # https://github.com/puma/puma/blob/master/docs/restart.md
  prune_bundler

  # old hot restart config; will need ansible change to tell systemctl to restart instead of reload
  # preload_app!
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
