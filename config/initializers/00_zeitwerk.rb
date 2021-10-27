# named 00_zeitwerk because Rails loads these in alphabetical order and
# production.rb needs these classes loaded

%w{extras lib}.each do |dir|
  Rails.autoloaders.main.push_dir(Rails.root.join(dir))
  Dir[File.join(Rails.root, dir, "*.rb")].sort.each {|l| require l }
end
