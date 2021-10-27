%w{extras lib}.each do |dir|
  Rails.autoloaders.main.push_dir(Rails.root.join(dir))
  Dir[File.join(Rails.root, dir, "*.rb")].sort.each {|l| require l }
end
