class IndexStoryJob < ApplicationJob
  queue_as :default

  def perform(story)
    client = ElasticSearch.client
    body = {
      title: story.title,
      author: story.user.username,
      url: story.url,
      domain: story.domain,
      description: story.description,
      tag: story.tags.pluck(:tag),
      body: story.story_cache,
      created_at: story.created_at,
      score: story.score,
      is_expired: story.is_expired,
      kind: 'story',
    }

    client.index(
      index: ElasticSearch.index,
      type: 'searchable',
      id: story.to_global_id.to_s,
      body: body
    )
  end
end
