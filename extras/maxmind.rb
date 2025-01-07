module Maxmind
  def self.uk? ip
    # database from https://db-ip.com/db/download/ip-to-country-lite
    @db ||= MaxMindDB.new("#{ENV["HOME"]}/dbip.mmdb")
    result = @db.lookup(ip)
    return false unless result.found?
    result.country.iso_code == "GB"
  end
end
