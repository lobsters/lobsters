unless ENV['SCHEMA']
  case ActiveRecord::Tasks::DatabaseTasks.current_config['adapter']
  when 'postgresql'
    ENV['SCHEMA'] = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.pg.rb')
  else
    ENV['SCHEMA'] = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
  end
end
