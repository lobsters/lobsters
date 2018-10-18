namespace :elastic do
  task create_index: [:environment] do
    ElasticSearch.client.indices.create(index: ElasticSearch.index)
  end

  task backfill: [:environment] do
    Story.all.each {|s| IndexStoryJob.perform_later(s) }
    Comment.all.each {|c| IndexCommentJob.perform_later(c) }
  end
end
