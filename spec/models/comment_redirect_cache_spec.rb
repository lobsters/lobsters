# typed: false

require "rails_helper"

describe CommentRedirectCache do
  around do |example|
    was_dir = Rails.application.config.comment_redirect_cache_dir
    Dir.mktmpdir("rspec-") do |dir|
      Rails.application.config.comment_redirect_cache_dir = dir
      example.run
    end
  ensure
    Rails.application.config.comment_redirect_cache_dir = was_dir
  end

  let(:dir) { Rails.application.config.comment_redirect_cache_dir }

  it "caches the destination url, no newline" do
    CommentRedirectCache.write("abc123", "/s/xyz789/title#c_abc123")

    expect(File.read(File.join(dir, "abc123"))).to eq("/s/xyz789/title#c_abc123")
  end

  it ".delete is idempotent" do
    CommentRedirectCache.write("abc123", "/s/xyz789/title#c_abc123")
    CommentRedirectCache.delete("abc123")
    CommentRedirectCache.delete("abc123")

    expect(Dir.children(dir)).to be_empty
  end
end
