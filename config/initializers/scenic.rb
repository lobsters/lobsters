Scenic.configure do |config|
  if ActiveRecord::Base.connection.adapter_name != 'PostgreSQL'
    config.database = Scenic::Adapters::MySQL.new
  end
end
