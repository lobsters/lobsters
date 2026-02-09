class Migrate
  def initialize
    Rails.application.eager_load!
  end

  def dump
    File.open("dump.yml", "w") do |file|
      ApplicationRecord.descendants.map do |application_record|
        column_names = application_record.columns.map { |c| c.name }
        # Models like Tag override as_json so can't use to_json(only: ...)
        application_record.find_in_batches do |batch|
          {
            "name" => application_record.name,
            "batch" => batch.map { |r| column_names.map { |column_name| [column_name, r[column_name]] }.to_h }
          }.then { file.write(YAML.dump_stream(it)) }
        end
      end
    end
  end

  def load
    # Don't enforce foreign keys on load, otherwise we would have to topoligically sort by foreign key dependency
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF;")

    File.open("dump.yml", "r") do |file|
      YAML.load_stream(file) do |document|
        document["name"].constantize.insert_all!(document["batch"])
      end
    end

    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON;")
  end
end

task dump_db: :environment do
  Migrate.new.dump
end

task load_db: :environment do
  Migrate.new.load
end
