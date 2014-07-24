module Lobsters
    class Config
        @@config_data = YAML.load_file("#{Rails.root}/config/configuration.yml")
        
        def self.[](option)
            @@config_data[option.to_sym]
        end 
    end
end
