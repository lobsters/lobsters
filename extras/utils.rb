# typed: false

class Utils
  # URI.parse is not very lenient, so we can't use it
  # requires a . in domain because we don't want people submitting links to internal hostnames
  URL_RE = /\A(?<protocol>https?):\/\/(?<domain>(?:[^.\/]+\.)+[a-z-]+)(?<port>:\d+)?(?:\/(?:[\w.~:\/?#\[\]@!$&'()*+,;=%-]*))?\z/i

  # utility that works on stringlikes (for possibly invalid user input + searches)
  # If this function changes, you should run Story.refresh_normalized_urls! and Link.refresh_normalized_urls!
  def self.normalize(url)
    return url if url.blank?
    url = url.to_s.dup # in case passed a Url or frozen string

    url.slice! %r{#.*$} # remove anchor
    url.slice! %r{/$} # remove trailing slash
    url.slice! %r{\.html?$} # remove .htm, .html

    # remove some common "directory index" pages that are commonly served for dirs
    url.slice! %r{/index$} # includes index.html? from previous
    url.slice! %r{/index\.php}
    url.slice! %r{/Default\.aspx$}

    url.slice! %r{https?://} # consider http and https the same
    url.sub!(/\Awww\d*\.(.+?\..+)/, '\1') # remove www\d* from domain if the url is not like www10.org

    url, *args = url.split(/[&?]/) # trivia: ?a=1?c=2 is a valid uri
    url ||= "" # if original url was just '#', ''.split made url nil
    if args.any?
      url += "?"
      url += args.map { |arg| arg.split("=") }.sort.map { |arg| arg.join("=") }.join("&")
    end

    # unify arxiv page and pdf based on their identifier https://arxiv.org/help/arxiv_identifier
    url = url.sub %r{^arxiv\.org/(?:abs|html|pdf)/(?<id>\d{4}\.\d{4,5}(?:v\d)?)(?:\.pdf)?}, 'arxiv.org/abs/\k<id>'

    # unify rfc-editor.org pages based on their URL structures:
    # https://www.rfc-editor.org/rfc/rfc9338.html
    # https://www.rfc-editor.org/info/rfc9338
    url = url.sub %r{rfc-editor\.org/(?:rfc|info)/rfc(\d+)[^/]*$}, 'rfc-editor.org/rfc/\1'

    url = url.sub %r{^m\.youtube\.com/}, "youtube.com/"
    url = url.sub %r{^youtu\.be/}, "youtube.com/watch?v="
    url = url.sub %r{^youtube\.com/.*v=(?<id>[A-Za-z0-9\-_]+).*}, 'youtube.com/watch?v=\k<id>'
    url.sub(
      %r{^youtube\.com/playlist\?.*list=(?<id>[A-Za-z0-9\-_]+).*},
      'youtube.com/playlist?list=\k<id>'
    )
  end

  def self.random_str(len)
    str = ""
    while str.length < len
      chr = OpenSSL::Random.random_bytes(1)
      ord = chr.unpack1("C")

      #          0            9              A            Z              a            z
      if ord.between?(48, 57) || ord.between?(65, 90) || ord.between?(97, 122)
        str += chr
      end
    end

    str
  end

  def self.silence_stream(*streams)
    on_hold = streams.collect(&:dup)
    streams.each do |stream|
      stream.reopen(File::NULL)
      stream.sync = true
    end
    yield
  ensure
    streams.each_with_index do |stream, i|
      stream.reopen(on_hold[i])
    end
  end
end
