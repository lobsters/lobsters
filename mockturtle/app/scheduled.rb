require "ircinch"
require "rss"
require "open-uri"
require "time"
require "sqlite3"

require_relative "./model"

class RSSWatcher
  def initialize(bot)
    sleep 15
    @bot = bot
  end

  def watch_github
    feed = 'https://github.com/lobsters/lobsters/commits/master.atom'
    loop do
      key = "rss/commits"
      newest = RSS::Parser.parse(feed)
      newest.items.reverse_each do |item|
        publishedAt = item.updated.content.to_i
        link = item.link.href[0, item.link.href.length - 33]
        lastSeen = Time.new.to_i

        Rss.find(key) do |f|
          lastSeen = f["timestamp"]
        end

        if publishedAt > lastSeen
          lastSeen = publishedAt

          puts "Broadcasting commit {lobsters commit: #{item.title.content.strip} (by #{item.author.name.content}) #{link}}"
          entry = "lobsters commit: #{item.title.content.strip} (by #{item.author.name.content}) #{link}"
          @bot.handlers.dispatch(:rss, nil, entry)
        end
        Rss.where(key: key).first_or_create().update("timestamp": lastSeen)
    end
    sleep 10 * 60 * 1000
    end
  end

  def watch_lobsters
    feed = "https://lobste.rs/newest.rss"
    loop do
      key = "rss/lobsters"
      newest = RSS::Parser.parse(feed)
      newest.items.reverse_each do |item|
        grouping = /(?<attribution>via|by) (?<username>.+)/.match(item.author.to_s)
        attr = grouping["attribution"] === "by" ? "by " : ""
        publishedAt = item.date.to_i
        categories = item.categories.map{|d| d.content}.join(' ')
        lastSeen = Time.new.to_i

        Rss.find(key) do |f|
          lastSeen = f["timestamp"]
        end

        if publishedAt > lastSeen
          lastSeen = publishedAt

          puts "Broadcasting story, { itemDate: #{item.date}, itemGuid: item.guid.content, #{lastSeen} }"
          entry = "#{item.title} [#{categories}] #{attr}#{grouping["username"]} #{item.guid.content}"
          @bot.handlers.dispatch(:rss, nil, entry)
        end
        Rss.where(key: key).first_or_create().update("timestamp": lastSeen)
      end
      sleep 5000
    end
  end
end

class RSSNotifier
  include Cinch::Plugin

  listen_to :rss

  def listen(m, entry)
    Channel("#church-ircinch").send entry
  end
end
