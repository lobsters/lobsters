namespace :tags do
    desc 'Loads new tasks from a custom YAML, fallback to approved_tags.yaml'
    task :load_from_yaml, [:filename] => :environment do |task, args|
        require 'yaml'
        # Gets file path from args or falls back to default
        tags_filepath = args[:filename] || 'approved_tags.yaml'
        # Parses YAML from string
        items = YAML.load_file(tags_filepath)
        # Maps every tag and if it's not present adds it to the DB
        items.map do |item|
            Tag.find_or_create_by! tag: item["tag"], description: item["description"], is_media: item["is_media"]
        end
    end
end
  