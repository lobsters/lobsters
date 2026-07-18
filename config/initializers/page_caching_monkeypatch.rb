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
# actionpack-page_caching is unmaintained, so I'm working around several limitations here.
#
# 1. We cache HTML, json, and rss, so this monkeypatch recognizes them and leaves them in place, but
#    tags everything else with .html.
#
# 2. We catch an error when caching files if the computed filename on disk is too long, due to the
#    prod filesystem only supporting 254 character names.
#
# 3. Fix a bug in write(): it calls open (creating/truncating the file), then writes on close.
#    In between, Caddy happily serves 0 byte empty files with status 200. Replaced with an atomic
#    rename.
#
# 4. write() calls File.atomic_write(path), which passes the path to Tempfile.open as a basename,
#    which prefixes a random 22 characters to it, which worsens problem 2. So this write() also
#    gives atomic_write a random filename and then renames a second time to the desired path. Which.

require "actionpack/page_caching"
require "active_support/core_ext/file/atomic"
require "zlib"

ActiveSupport.on_load(:action_controller) do
  # https://github.com/rails/actionpack-page_caching/blob/d929689748f09c5d7c73cefbd9326701dcf52a30/lib/action_controller/caching/pages.rb
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
        if !%w[.html .json .rss].include? File.extname(name)
          name + (extension || default_extension)
        else
          name
        end
      end

      def write(content, path, gzip)
        return unless path

        dir = File.dirname(path)
        FileUtils.makedirs(dir)
        tmp = File.join(dir, ".#{SecureRandom.hex(8)}")

        File.atomic_write(tmp) { |f| f.write(content) }
        File.rename(tmp, path)

        if gzip
          File.atomic_write(tmp) { |f| f.write(Zlib.gzip(content, level: gzip)) }
          File.rename(tmp, "#{path}.gz")
        end
      ensure
        FileUtils.rm(tmp.to_s, force: true)
      end
    end
  end
end
