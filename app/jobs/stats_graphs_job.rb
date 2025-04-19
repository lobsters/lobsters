class StatsGraphsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Stats.get_users_graph(false)

    Stats.get_active_users_graph(false)

    Stats.get_stories_graph(false)

    Stats.get_comments_graph(false)

    Stats.get_votes_graph(false)
  end
end
