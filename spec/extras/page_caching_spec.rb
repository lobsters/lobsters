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

  let(:cache_dir) { @cache_dir }
  # (cache_directory, default_extension)
  let(:page_cache) { ActionController::Caching::Pages::PageCache.new(cache_dir, "html") }

  describe "#cache_file" do
    context "with a non-html extension" do
      it "returns the file path with html extension" do
        expect(page_cache.cache_file("youtube.com", "html")).to eq("youtube.com.html")
      end
    end

    context "with a html extension" do
      it "returns the file path with html extension" do
        expect(page_cache.cache_file("youtube.com.html", "html")).to eq("youtube.com.html")
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
  end
end
