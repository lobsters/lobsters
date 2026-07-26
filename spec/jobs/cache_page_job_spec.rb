# typed: false

require "rails_helper"

RSpec.describe CachePageJob, type: :job do
  describe "#perform" do
    let!(:story) { create(:story) }
    let(:cache_dir) { ActionController::Base.page_cache_directory }
    let(:story_dir) { File.join(cache_dir, "s", story.short_id) }

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

    it "writes the rendered page to the cache" do
      CachePageJob.perform_now(Routes.title_path(story))

      file = File.join(story_dir, "#{story.title_as_slug}.html")
      expect(File.read(file)).to include(story.title)
    end

    it "sweeps cached copies at old slugs after a title edit" do
      FileUtils.mkdir_p(story_dir)
      File.write(File.join(story_dir, "old_slug.html"), "stale")

      CachePageJob.perform_now(Routes.title_path(story))

      expect(Dir.children(story_dir)).to eq(["#{story.title_as_slug}.html"])
    end

    it "leaves dotfiles alone so it can't eat cache_page tempfiles" do
      FileUtils.mkdir_p(story_dir)
      File.write(File.join(story_dir, ".tmpfile"), "in-flight write")

      CachePageJob.perform_now(Routes.title_path(story))

      expect(File.exist?(File.join(story_dir, ".tmpfile"))).to be true
    end

    it "doesn't sweep neighboring pages cached at the root" do
      File.write(File.join(cache_dir, "active.html"), "cached")

      CachePageJob.perform_now("/newest")

      expect(File.exist?(File.join(cache_dir, "newest.html"))).to be true
      expect(File.exist?(File.join(cache_dir, "active.html"))).to be true
    end

    it "raises without writing or sweeping when the page doesn't render" do
      FileUtils.mkdir_p(story_dir)
      File.write(File.join(story_dir, "#{story.title_as_slug}.html"), "stale")
      story.update_columns(is_deleted: true)

      expect { CachePageJob.perform_now(Routes.title_path(story)) }
        .to raise_error(/CachePageJob: 404/)

      expect(File.read(File.join(story_dir, "#{story.title_as_slug}.html"))).to eq("stale")
    end
  end
end
