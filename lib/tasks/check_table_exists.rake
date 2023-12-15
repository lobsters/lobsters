# typed: false

desc "Checks if a table exists"
task :table_exists, [:table_name] => :environment do |t, args|
  table_name = args.table_name
  begin
    if ActiveRecord::Base.connection.table_exists?(table_name)
      puts "true"
    else
      puts "false"
    end
  rescue ActiveRecord::NoDatabaseError
    puts "false"
  end
end
