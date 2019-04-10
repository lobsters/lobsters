namespace :tags do
    desc 'Loads new tasks from approved_tags.yaml'
    task :load_from_yaml, [:filename] => :environment do |task, args|
        require 'yaml'
        # Gets file path from args or falls back to default
        tags_filepath = args[:filename] || 'approved_tags.yaml'
        # Loads file as string
        file_string = File.read(File.join Rails.root, tags_filepath)
        # Parses YAML from string
        tags = YAML.load(file_string)
        # Maps every tag and eventually adds it to the DB
        tags.map do |tag|
            Tag.find_or_create_by!(tag: tag)
        end
    end
end
  
