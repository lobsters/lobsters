require "ircinch"
require "json"
require "nokogiri"
require "time"

require_relative "../../extras/sponge.rb"

class Seen
  class SeenStruct < Struct.new(:who, :where, :time)
    def to_s
      "I last saw #{who} in #{where} at #{time.asctime}."
    end
  end

  include Cinch::Plugin
  listen_to :channel
  set :prefix, /^./
  match(/seen (.+)/)

  def initialize(*args)
    super
    @users = {}
  end

  def listen(m)
    @users[m.user.nick] = SeenStruct.new(m.user, m.channel, Time.now)
  end
  
  def execute(m, nick)
    if @users.key?(nick)
      m.reply @users[nick].to_s
    else
      m.reply "I haven't seen #{nick}"
    end
  end
end

class Tell
  class TellStruct < Struct.new(:who, :message, :whom)
    def to_s
      "#{who}: #{message} (from #{whom})"
    end
  end

  include Cinch::Plugin
  listen_to :channel
  set :prefix, /^./
  match(/tell (.+) (.+)/)

  def initialize(*args)
    super
    @tells = {}
  end

  def listen(m)
    if @tells.key?(m.user.nick)
      m.reply @tells.delete(m.user.nick).to_s
    end
  end
  
  def execute(m, nick, message)
    @tells[nick] = TellStruct.new(nick, message, m.user.nick)
  end
end

class Salute
  include Cinch::Plugin
  set :prefix, /^./
  match('salute')

  def execute(m)
    leaves = ['(V)', '(\\/)', '(\\_/)', 'V', 'v', '(v)']
    stems = ['_!_!_', '.v.', '_00_']
    leaf = leaves.sample
    stem = stems.sample
    m.reply "#{leaf}#{stem}#{leaf}"
  end
end

class AutoTitle
  include Cinch::Plugin
  listen_to :channel

  def truncate(text, length = 100, truncate_string = '...')
    if text
      l = length - truncate_string.chars.length
      (text.length > length ? text[0...l] + truncate_string : text).to_s
    end
  end

  def listen(m)
    maxTitleSize = 200
    youtubeDomains = [
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
      'youtu.be',
      'youtube-nocookie.com',
      'music.youtube.com',
    ]
    urls = URI.extract(m.message, ["http", "https"])
    s = Sponge.new()
    unless urls.empty?
      urls.each do |targetUrl|
        url = URI(targetUrl)
        if youtubeDomains.include?(url.host)
          oembedUrl = URI("https://www.youtube.com/oembed")
          oembedUrl.query = URI.encode_www_form("url" => targetUrl)
          req = s.fetch(oembedUrl.to_s)
          urlJson = JSON.parse(req.body)
          truncatedTitle = truncate(urlJson["title"], maxTitleSize)
          author = urlJson["author_name"] ? urlJson["author_name"] : 'No Author'
          m.reply "#{truncatedTitle} - by #{author}"
        else
          req = s.fetch(url.to_s)
          doc = Nokogiri::HTML(req.body)
          title = doc.at_css("title").text
          truncatedTitle = truncate(title, maxTitleSize)
          m.reply "#{truncatedTitle}"
        end
      end
    end
  end
end
