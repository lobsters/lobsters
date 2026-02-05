# Local development version of the commands run in CI (check.yml).

require "rspec/core/rake_task"
require "standard/cli"
require "brakeman/commandline"
require "database_consistency"

RSpec::Core::RakeTask.new(:spec)

# Override to prevent Brakeman from exiting this entire task on Brakeman's completion.
module Brakeman
  class Commandline
    def self.quit(exit_code = 0, message = nil)
      warn message if message
      Brakeman.cleanup
      # omitted: `exit exit_code`
    end
  end
end

desc "Local development version of the commands run in CI (check.yml)"
task build: :environment do
  puts "\n◾ Running linter (Standard)..."
  Standard::Cli.new(["--fix-unsafely"]).run

  puts "\n◾ Running security check (Brakeman)..."
  Brakeman::Commandline.start({quiet: true, summary_only: :no_summary})

  puts "\n◾ Running database consistency checks (DatabaseConsistency)..."
  DatabaseConsistency.run([".database_consistency.ignore.yml"])

  puts "\n◾ Running tests (RSpec)..."
  Rake::Task["spec"].invoke
end
