class AddTagRegex < ActiveRecord::Migration[5.2]
    def change
      add_column :tags, :suggestion_regex, :string, :default => ""
    end
  end
