# Local development version of the commands run in CI (check.yml).

return unless Rails.env.local?
require "brakeman/commandline"

# Override to prevent RSpec from exiting this entire task on RSpec's completion.
module RSpec
  module Core
    class RakeTask
      def run_task(verbose)
        command = spec_command
        puts command if verbose

        if with_clean_environment
          return if system({}, command, unsetenv_others: true)
        elsif system(command)
          return
        end

        puts failure_message if failure_message

        return unless fail_on_error
        warn "#{command} failed" if verbose
        # exit $?.exitstatus || 1 # omitted
      end
    end
  end
end

# Override to prevent Brakeman from exiting this entire task on Brakeman's completion.
module Brakeman
  class Commandline
    def self.quit(_exit_code = 0, message = nil)
      warn message if message
      Brakeman.cleanup
      # `exit exit_code` # omitted
    end
  end
end

desc "Local development version of the commands run in CI (check.yml)"
task build: :environment do
  puts "\n◾ Running tests (RSpec)..."
  Rake::Task["spec"].invoke

  puts "\n◾ Running linter (Standard)..."
  Standard::Cli.new(["--fix-unsafely"]).run

  puts "\n◾ Running security check (Brakeman)..."
  Brakeman::Commandline.start({quiet: true, summary_only: :no_summary})

  puts "\n◾ Running database consistency checks (DatabaseConsistency)..."
  DatabaseConsistency.run([".database_consistency.ignore.yml"])
end
