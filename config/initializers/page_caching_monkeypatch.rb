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
#
# We also catch an error when caching files if the computed filename on disk is too long, due to the
# filesystem used in production only supporting 254 character names.

require "actionpack/page_caching"

ActiveSupport.on_load(:action_controller) do
  module ActionController::Caching::Pages # standard:disable Lint/ConstantDefinitionInBlock
    class PageCache
      module WritePatch
        # Override: refuse to cache paths with long filenames
        def write(...)
          super
        rescue Errno::ENAMETOOLONG => e
          # #1826 - Handle write errors from filenames being longer than 255 bytes
          Rails.logger.info "Failed to cache page #{e.inspect}"
          nil
        end
      end

      prepend WritePatch

      def cache_file(path, extension)
        name = if path.empty? || path =~ %r{\A/+\z}
          "/index"
        else
          URI::DEFAULT_PARSER.unescape(path.chomp("/"))
        end

        # original:
        #   if File.extname(name).empty?
        # monkeypatch:
        if File.extname(name) != ".html"
          name + "." + (extension || default_extension)
        else
          name
        end
      end
    end
  end
end
