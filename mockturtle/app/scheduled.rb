require "ircinch"
require "rss"
require "open-uri"
require "time"
require "sqlite3"

class RSSWatcher
  def initialize(bot, db)
    sleep 5
    @bot = bot
    @db  = db
  end

  def watch_github
    feeds = {
      "lobsters" => 'https://github.com/lobsters/lobsters/commits/master.atom',
      "lobstersAnsible" => 'https://github.com/lobsters/lobsters-ansible/commits/master.atom',
      "mockturtle" => 'https://github.com/lobsters/mockturtle/commits/develop.atom'
    }
    loop do
      feeds.each do |repo, feed|
        key = "rss/commits/#{repo}"
        lastSeen = Time.new().to_i

        newest = RSS::Parser.parse(feed)
        newest.items.reverse_each do |item|
          publishedAt = item.updated.content.to_i
          link = item.link.href[0, item.link.href.length - 33]

          if publishedAt > lastSeen
            lastSeen = publishedAt

            puts "Broadcasting commit {#{repo} commit: #{item.title.content.strip} (by #{item.author.name.content}) #{link}}"
            entry = "#{repo} commit: #{item.title.content.strip} (by #{item.author.name.content}) #{link}"
            @bot.handlers.dispatch(:rss, nil, entry)
          end
        end
      end
      sleep 10 * 60 * 1000
    end
  end

  def watch_lobsters
    loop do
      feed = "https://lobste.rs/newest.rss"
      lastSeen = Time.new().to_i

      newest = RSS::Parser.parse(feed)
      newest.items.reverse_each do |item|
        grouping = /(?<attribution>via|by) (?<username>.+)/.match(item.author.to_s)
        attr = grouping["attribution"] === "by" ? "by " : ""
        publishedAt = item.date.to_i
        categories = item.categories.map{|d| d.content}.join(' ')

        if publishedAt > lastSeen
          lastSeen = publishedAt

          puts "Broadcasting story, { itemDate: #{item.date}, itemGuid: item.guid, #{lastSeen} }"
          entry "#{item.title} [#{categories}] #{attr}#{grouping["username"]} #{item.guid}"
          @bot.handlers.dispatch(:rss, nil, entry)
        end
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
