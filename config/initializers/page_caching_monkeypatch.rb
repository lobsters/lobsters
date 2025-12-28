# https://github.com/lobsters/lobsters/issues/1825
# actionpack-page_caching maps URLs to filesystem paths and either appends a ".html" or, if the URL
# has a ., uses the existing extension. This is mostly correct, so that it could cache (say) a json
# file and the web server would see the extension to serve it with the correct MIME type. However,
# when we try to save a route like "youtube.com", it thinks ".com" is an extension and creates a
# file public/cache/youtube.com instead of public/cache/youtube.com.html, so if someone soon-after
# loads the url /youtube.com/page/2 the cache throws a 500 on write because 'youtube.com' is a file,
# not a directory. (Same kind of bug if the pages are loaded in the reverse order; the second hit
# fails to write the file 'youtube.com' if it exists as a directory.)
#
# actionpack-page_caching is unmaintained, so I'm working around this limitation rather than
# report or contribute a fix upstream.
#
# We only cache HTML pages, so this monkeypatch forces the '.html' extension.

require "actionpack/page_caching"

ActiveSupport.on_load(:action_controller) do
  module ActionController::Caching::Pages # standard:disable Lint/ConstantDefinitionInBlock
    class PageCache
      def cache_file(path, extension)
        name = if path.empty? || path =~ %r{\A/+\z}
          "/index"
        else
          URI::DEFAULT_PARSER.unescape(path.chomp("/"))
        end

        # original:
        #   if File.extname(name).empty?
        # monkeypatch:
        full_name =
          if File.extname(name) != ".html"
            name + "." + (extension || default_extension)
          else
            name
          end

        # Work around names being too long - we only allow names under 255 bytes long
        if full_name.length <= 255
          full_name
        else
          # Generate a SHA256 digest of the value and use that instead, ensuring extension is HTML
          "#{Digest::SHA256.hexdigest(full_name)}.html"
        end
      end
    end
  end
end
