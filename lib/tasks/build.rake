# Local development version of the commands run in CI (check.yml).

return unless Rails.env.local?

desc "Local development version of the commands run in CI (check.yml)"
task :build do
  # endlessly struggling to match the CI env so dev builds fail and pass together
  ci_test_env = {
    "CI" => "true",
    "RAILS_ENV" => "test",
    "RUBYOPT" => "--yjit --enable-frozen-string-literal --debug-frozen-string-literal"
  }
  failed = []
  step = ->(name, *command) do
    puts "\n◾ Running #{name}..."
    failed << name unless system(*command)
  end

  step.call("tests (RSpec)", ci_test_env, "bundle", "exec", "rspec")
  step.call("linter (Standard)", "bundle", "exec", "standardrb", "--fix-unsafely")
  step.call("security check (Brakeman)", "bundle", "exec", "brakeman", "--quiet", "--no-summary", "--ensure-ignore-notes")
  step.call("database consistency checks (DatabaseConsistency)", ci_test_env,
    "bundle", "exec", "database_consistency", "--config", ".database_consistency.ignore.yml")
  step.call("Ruby version check of app and Dockerfile", "script/check_dockerfile_ruby_version.sh")

  abort "\n◾ Failed: #{failed.join(", ")}" if failed.any?
  puts "\n◾ Build passed"
end
