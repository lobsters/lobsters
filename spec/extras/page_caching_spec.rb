# typed: false

require "rails_helper"

RSpec.describe "page caching monkeypatch" do
  # Give each example a new temprary folder to cache into
  around do |example|
    Dir.mktmpdir("rspec-") do |dir|
      @cache_dir = dir
      example.run
    end
  end

  # in actionpack-page_caching extensions include their leading '.'

  let(:cache_dir) { @cache_dir }
  # (cache_directory, default_extension)
  let(:page_cache) { ActionController::Caching::Pages::PageCache.new(cache_dir, ".html") }

  describe "#cache_file" do
    context "with a non-html extension" do
      it "returns the file path with html extension" do
        expect(page_cache.cache_file("youtube.com", ".html")).to eq("youtube.com.html")
      end
    end

    context "with rss extension" do
      it "returns the file path with html extension" do
        expect(page_cache.cache_file("newest.rss", ".html")).to eq("newest.rss")
      end
    end

    context "with a html extension" do
      it "returns the file path with html extension" do
        expect(page_cache.cache_file("youtube.com.html", ".html")).to eq("youtube.com.html")
      end
    end

    context "with a trailing slash" do
      it "returns the same file path" do
        expect(page_cache.cache_file("/newest", ".html")).to eq("/newest.html")
        expect(page_cache.cache_file("/newest/", ".html")).to eq("/newest.html")
      end
    end

    context "with percent-encoded path traversal" do
      let(:unsafe) { ActionController::Caching::Pages::PageCache::UnsafePath }

      it "refuses an encoded ../ that would write a sibling of another page's cache file" do
        expect { page_cache.cache_file("/page/%2E%2E%2Findex%2Ehtml%2Fx", ".html") }.to raise_error(unsafe)
      end

      it "refuses an encoded ../ that would overwrite another page's cache file" do
        expect { page_cache.cache_file("/page/%2E%2E%2Fabout%2Ehtml", ".html") }.to raise_error(unsafe)
      end

      it "refuses an encoded . that would change the extension" do
        expect { page_cache.cache_file("/page/2%2Ejson", ".html") }.to raise_error(unsafe)
      end

      it "refuses an encoded / that would add a directory" do
        expect { page_cache.cache_file("/page/2%2Fx", ".html") }.to raise_error(unsafe)
      end

      it "refuses literal dot segments" do
        expect { page_cache.cache_file("/s/../index", ".html") }.to raise_error(unsafe)
      end

      it "still unescapes other characters" do
        expect(page_cache.cache_file("/t/c%2B%2B", ".html")).to eq("/t/c++.html")
      end

      it "still caches the root path as index" do
        expect(page_cache.cache_file("/", ".html")).to eq("/index.html")
      end
    end
  end

  describe "#cache" do
    context "with a filename longer than filesystem can handle" do
      let(:path) { "#{"a" * 249}.html" } # 254 in length

      before { allow(File).to receive(:open).and_raise(Errno::ENAMETOOLONG, "File name too long - #{path}") }

      it "does not cache the file" do
        expect(page_cache.cache("something here\n", path, nil, nil)).to be_nil
      end
    end

    it "doesn't cache path traversal" do
      expect(page_cache.cache("frontpage\n", "/page/%2E%2E%2Findex%2Ehtml%2Fx", nil, nil)).to be_nil
      expect(Dir.children(cache_dir)).to be_empty
    end
  end
end
