# typed: false

SitemapGenerator::Sitemap.default_host = "https://lobste.rs"

# https://developers.google.com/search/blog/2023/06/sitemaps-lastmod-ping
SitemapGenerator::Sitemap.search_engines = {}

check_hourly = 4.days.ago
check_daily = 2.weeks.ago
top_score = Story.all.maximum("score")

SitemapGenerator::Sitemap.create do
  %w[/about /chat].each do |path|
    add path, changefreq: "monthly", lastmod: nil
  end

  add recent_path, changefreq: "always", priority: 1
  add newest_path, changefreq: "always", priority: 1
  add comments_path, changefreq: "always", priority: 1

  Story.order("id desc").find_each do |story|
    lastmod = story.last_comment_at || story.created_at

    changefreq = "monthly"
    changefreq = "daily" if lastmod >= check_daily
    changefreq = "hourly" if lastmod >= check_hourly

    priority = 1.0 * story.score / top_score
    add Routes.title_path(story), lastmod: lastmod, changefreq: changefreq, priority: priority
  end
end
