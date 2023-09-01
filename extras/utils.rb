class Utils
  # URI.parse is not lenient enough
  # rubocop: disable Style/RegexpLiteral
  def self.normalize_url url
    return "" if url == ""
    return nil if url.nil?

    url = url.dup # copy in case frozen

    url.slice! %r{#.*$} # remove anchor
    url.slice! %r{/$} # remove trailing slash
    url.slice! %r{/index.html$} # remove index.html
    url = url.sub %r{\.htm$}, ".html" # fix microsoft naming

    url.slice! %r{https?://} # consider http and https the same
    url.slice! %r{^(www\d*\.)} # remove www\d* from domain

    url, *args = url.split(/[&\?]/) # trivia: ?a=1?c=2 is a valid uri
    if args.any?
      url += "?"
      url += args.map { |arg| arg.split("=") }.sort.map { |arg| arg.join("=") }.join("&")
    end

    # unify arxiv page and pdf based on their identifier https://arxiv.org/help/arxiv_identifier
    url = url.sub %r{^arxiv\.org/(?:abs|pdf)/(?<id>\d{4}\.\d{4,5})(?:\.pdf)?}, 'arxiv.org/abs/\k<id>'

    url = url.sub %r{^m\.youtube\.com/}, "youtube.com/"
    url = url.sub %r{^youtu\.be/}, "youtube.com/watch?v="
    url = url.sub %r{^youtube\.com/.*v=(?<id>[A-Za-z0-9\-_]+).*}, 'youtube.com/watch?v=\k<id>'
    url.sub(
      %r{^youtube\.com/playlist\?.*list=(?<id>[A-Za-z0-9\-_]+).*},
      'youtube.com/playlist?list=\k<id>'
    )
  end
  # rubocop: enable Style/RegexpLiteral

  def self.random_str(len)
    str = ""
    while str.length < len
      chr = OpenSSL::Random.random_bytes(1)
      ord = chr.unpack1("C")

      #          0            9              A            Z              a            z
      if (ord >= 48 && ord <= 57) || (ord >= 65 && ord <= 90) || (ord >= 97 && ord <= 122)
        str += chr
      end
    end

    str
  end

  def self.silence_stream(*streams)
    on_hold = streams.collect(&:dup)
    streams.each do |stream|
      stream.reopen("/dev/null")
      stream.sync = true
    end
    yield
  ensure
    streams.each_with_index do |stream, i|
      stream.reopen(on_hold[i])
    end
  end
end
