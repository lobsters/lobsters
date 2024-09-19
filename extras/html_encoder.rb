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
    end
  end
end
