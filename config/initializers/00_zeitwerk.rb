# typed: false

# named 00_zeitwerk because Rails loads these in alphabetical order and
# production.rb needs these classes loaded

# prevent zeitwerk from failing on prod boot because these patches don't match
# its expected filenames
Rails.autoloaders.main.ignore(Rails.root.join("extras/prohibit*rb"))

if Rails.env.production? &&
    !File.read(Rails.root.join("config/initializers/production.rb").to_s).split("\n")[0..5].join(" ").include?("extras")
  raise <<~KLUDGE_APOLOGY
    Sorry for the hassle, but to fix https://github.com/lobsters/lobsters/issues/1246
    you need to copy this line of code to your config/initializers/production.rb:

    Dir[Rails.root.join("extras", "*.rb").to_s].each {|f| require f }

    It goes inside the `if Rails.env.production`, see production.rb.sample.

    Perhaps all of config/initalizers/production.rb should be moved into
    config/environments/production.rb but that's more weird boot issues than I can
    take on today.
  KLUDGE_APOLOGY
end
