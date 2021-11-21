# named 00_zeitwerk because Rails loads these in alphabetical order and
# production.rb needs these classes loaded

# prevent zeitwerk from failing on prod boot because these patches don't match
# its expected filenames
Rails.autoloaders.main.ignore(Rails.root.join('extras/prohibit*rb'))
Rails.autoloaders.main.ignore(Rails.root.join('lib/monkey.rb'))
require Rails.root.join('lib/monkey.rb').to_s

%w{extras lib}.each do |dir|
  Rails.autoloaders.main.push_dir(Rails.root.join(dir))
  Dir[File.join(Rails.root, dir, "*.rb")].sort.each {|l| require l }
end
