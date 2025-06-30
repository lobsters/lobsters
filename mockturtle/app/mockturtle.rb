require "ircinch"
require "sqlite3"

require_relative "./commands"
require_relative "./db"
require_relative "./scheduled"


bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.libera.chat"
    c.channels = ["#church-ircinch"]
    c.plugins.plugins = [RSSNotifier, Seen, Salute, Tell, AutoTitle]
  end
end


db = setup_db_conn()

Thread.new { RSSWatcher.new(bot, db).watch_github }
Thread.new { RSSWatcher.new(bot, db).watch_lobsters }

bot.start
