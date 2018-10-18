desc 'Load some data into elasticsearch via wikipeida'
task fake_elastic: :environment do
  require 'wikipedia'
  title = ENV.fetch('TITLE', 'Lobster')

  extlinks = Wikipedia.find(title).extlinks
  extlinks.each do |link|
    story = Story.new(user: User.first, url: link, title: link, tags: [Tag.first])
    next unless story.save

    puts "Added #{link}"
    if s.story_cache.blank?
      s.fetch_story_cache!
      s.index_in_elasticsearch
    end
  end
end
