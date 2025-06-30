require 'active_record'
require "ircinch"
require "json"
require 'sqlite3'

require_relative "./commands"
require_relative "./model"
require_relative "./scheduled"

config_file_path = ARGV[0]
json_string = File.read(config_file_path)
config = JSON.parse(json_string)

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: config["db"]["path"]
)

@first_run = !Rss.table_exists?

# Create the table (migration-like setup)
if @first_run
  ActiveRecord::Schema.define do
    create_table :rss do |t|
      t.string :key
      t.integer :timestamp
      t.timestamps
    end
    add_index :rss, :key, unique: true
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = config["irc"]["server"]
    c.channels = config["irc"]["channels"]
    c.nick = config["irc"]["nick"]
    c.plugins.plugins = [RSSNotifier, Seen, Salute, Tell, AutoTitle]
  end
end


Thread.new { RSSWatcher.new(bot).watch_github }
Thread.new { RSSWatcher.new(bot).watch_lobsters }

bot.start
