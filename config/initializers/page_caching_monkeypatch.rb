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
#
# 5. cache_file() unescapes the request path to name the file and cache_path()'s start_with? check
#    only prevents escaping the cache dir entirely. Rails matches against the escaped path, so
#    percent-encoded '../' lets an attacker choose the filename a page is cached under, like:
#     - arbitrary names that won't be swept, filling the disk
#     - write a page with a trailing slash, so newest.html becomes newest/index.html
#     - write a page under the filename for another page, so /a serves the content of /b
#     - write a page to directory to block caching, eg 'index.html/a.html', so the root path can't
#       be cached as 'index.html' (this kills the lobster)
#
# Real obvious the correct fix for all of these would be to cache into a sqlite db and write a Caddy
# module to read from it.

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
          # #1826 discard write errors from filenames being longer than 255 bytes
          nil
        end
      end

      prepend WritePatch

      class UnsafePath < StandardError; end

      module CachePatch
        # Override: refuse to cache paths with directory traversal/rewrites
        def cache(...)
          super
        rescue UnsafePath
          nil
        end
      end

      prepend CachePatch

      def cache_file(path, extension)
        if path.empty? || path =~ %r{\A/+\z}
          name = "/index"
        else
          raw = path.chomp("/")
          name = URI::DEFAULT_PARSER.unescape(raw)

          # #5: refuse encoded '.' or '/', '//', '/./', '/../'
          if name.count("./") != raw.count("./") || name.match(%r{/\.{0,2}(/|\z)})
            raise UnsafePath, "unescaping #{path.inspect} added a '.' or '/'"
          end
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
