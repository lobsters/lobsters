# typed: false


Rails.backtrace_cleaner.add_silencer { |line| line.include?("config/initializers/reject_spoofed_ips") }

# You can also remove all the silencers if you're trying to debug a problem
# that might stem from framework code.
# Rails.backtrace_cleaner.remove_silencers!
