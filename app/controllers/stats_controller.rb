# typed: false

class StatsController < ApplicationController
  def index
    @title = "Stats"

    @users_graph = Stats.get_users_graph(true)

    @active_users_graph = Stats.get_active_users_graph(true)

    @stories_graph = Stats.get_stories_graph(true)

    @comments_graph = Stats.get_comments_graph(true)

    @votes_graph = Stats.get_votes_graph(true)
  end
end
