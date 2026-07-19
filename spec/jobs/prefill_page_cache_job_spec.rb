# typed: false

require "rails_helper"

RSpec.describe PrefillPageCacheJob, type: :job do
  describe "#perform" do
    let!(:story) { create(:story) }

    around do |example|
      was_caching = ActionController::Base.perform_caching
      was_dir = ActionController::Base.page_cache_directory
      Dir.mktmpdir("rspec-") do |dir|
        ActionController::Base.perform_caching = true
        ActionController::Base.page_cache_directory = dir
        example.run
      end
    ensure
      ActionController::Base.perform_caching = was_caching
      ActionController::Base.page_cache_directory = was_dir
    end

    it "writes cache files for the homepage, nav pages, /newest, and /users" do
      dir = ActionController::Base.page_cache_directory
      PrefillPageCacheJob.perform_now

      expect(Dir.glob("**/*.html", base: dir)).to include("index.html", "active.html")
      expect(File.read(File.join(dir, "index.html"))).to include(story.title)
    end
  end
end
