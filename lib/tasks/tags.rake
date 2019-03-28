namespace :tags do
    desc 'Loads new tasks from approved_tags.yaml'
    task load_from_yaml: :environment do
        require 'yaml'
        # Default filepath of the tags file
        TAGS_FILEPATH = 'approved_tags.yaml'
        # Loads file as string
        file_string = File.read(File.join Rails.root, TAGS_FILEPATH)
        # Parses YAML from string
        tags = YAML.load(file_string)
        # Maps every tag and eventually adds it to the DB
        tags.map do |tag|
            Tag.find_or_create_by! tag: tag
        end
    end
end
  