# typed: false

require "rails_helper"

RSpec.describe "page caching monkeypatch" do
  # (cache_directory, default_extension)
  let(:page_cache) { ActionController::Caching::Pages::PageCache.new(File::NULL, "html") }

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
  end
end
