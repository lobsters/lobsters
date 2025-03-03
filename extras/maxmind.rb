module Maxmind
  DB_PATH = "#{ENV["HOME"]}/dbip.mmdb".freeze

  def self.uk? ip
    return false unless File.exist? DB_PATH

    # database from https://db-ip.com/db/download/ip-to-country-lite
    @db ||= MaxMindDB.new(DB_PATH, MaxMindDB::LOW_MEMORY_FILE_READER)
    result = @db.lookup(ip)
    return false unless result.found?
    result.country.iso_code == "GB"
  end
end
