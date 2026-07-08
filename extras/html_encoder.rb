# typed: false

require "cgi"

module HtmlEncoder
  HTML_ENTITIES = HTMLEntities.new

  class << self
    def encode(string, type = :decimal)
      HTML_ENTITIES.encode(string, type)
    end

    def decode(encoded_string)
      CGI.unescape_html(encoded_string)
    # bug: https://github.com/ruby/cgi/issues/103
    # https://lobste.rs/s/ndtuji/using_unicode_half_stars_symbols_ratings has an unprintable char
    rescue Encoding::CompatibilityError
      encoded_string # just don't get &nbsp; and such translated
    end
  end
end
