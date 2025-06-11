class StatsGraphsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Stats.fill_users_graph_cache
    Stats.fill_active_users_graph_cache
    Stats.fill_stories_graph_cache
    Stats.fill_comments_graph_cache
    Stats.fill_votes_graph_cache
    nil
  end
end
