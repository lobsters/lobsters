class IndexCommentJob < ApplicationJob
  queue_as :default

  def perform(comment)
    client = ElasticSearch.client
    body = {
      author: comment.user.username,
      body: comment.comment,
      created_at: comment.created_at,
      score: comment.score,
      is_expired: comment.is_deleted || comment.story.is_expired,
      kind: 'comment',
    }

    client.index(
      index: ElasticSearch.index,
      type: 'searchable',
      id: comment.to_global_id.to_s,
      body: body
    )
  end
end
