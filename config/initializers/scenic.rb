# typed: false

scenic_multidb_adapter = Class.new do
  def initialize
    @mysql = Scenic::Adapters::MySQL.new
    @sqlite = Scenic::Adapters::Sqlite.new
  end

  def method_missing(...)
    adapter.__send__(...)
  end

  def respond_to_missing? name, include_private
    adapter.respond_to? name
  end

  private

  def adapter
    case ActiveRecord::Base.connection
    when ActiveRecord::ConnectionAdapters::TrilogyAdapter
      @mysql
    when ActiveRecord::ConnectionAdapters::SQLite3Adapter
      @sqlite
    else
      raise "Unsupported adapter"
    end
  end
end

Scenic.configure do |config|
  config.database = scenic_multidb_adapter.new
end
