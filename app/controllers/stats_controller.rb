# typed: false

class StatsController < ApplicationController
  FIRST_MONTH = Time.new(2012, 7, 3).utc.freeze
  TIMESCALE_DIVISIONS = "1 year".freeze

  def index
    @title = "Stats"

    @users_graph = monthly_graph("users_graph", {
      graph_title: "Users joining by month",
      scale_y_divisions: 100
    }) {
      User.group("date_format(created_at, '%Y-%m')").count.to_a.flatten
    }

    @active_users_graph = monthly_graph("active_users_graph", {
      graph_title: "Active users by month",
      scale_y_divisions: 500
    }) {
      User.connection.select_all(<<~SQL
        SELECT ym, count(distinct user_id)
        FROM (
          SELECT date_format(created_at, '%Y-%m') as ym, user_id FROM stories
          UNION
          SELECT date_format(updated_at, '%Y-%m') as ym, user_id FROM votes
          UNION
          SELECT date_format(created_at, '%Y-%m') as ym, user_id FROM comments
        ) as active_users
        GROUP BY 1
        ORDER BY 1 asc;
      SQL
                                ).to_a.map(&:values).flatten
    }

    @stories_graph = monthly_graph("stories_graph", {
      graph_title: "Stories submitted by month",
      scale_y_divisions: 250
    }) {
      Story.group("date_format(created_at, '%Y-%m')").count.to_a.flatten
    }

    @comments_graph = monthly_graph("comments_graph", {
      graph_title: "Comments posted by month",
      scale_y_divisions: 1_000
    }) {
      Comment.group("date_format(created_at, '%Y-%m')").count.to_a.flatten
    }

    @votes_graph = monthly_graph("votes_graph", {
      graph_title: "Votes cast by month",
      scale_y_divisions: 10_000
    }) {
      Vote.group("date_format(updated_at, '%Y-%m')").count.to_a.flatten
    }
  end

  private

  def monthly_graph(cache_key, opts)
    Rails.cache.fetch(cache_key, expires_in: 1.day) {
      defaults = {
        width: 800,
        height: 300,
        graph_title: "Graph",
        show_graph_title: false,
        no_css: false,
        key: false,
        scale_x_integers: true,
        scale_y_integers: false,
        show_data_values: false,
        show_x_guidelines: false,
        show_x_title: false,
        x_title: "Time",
        show_y_title: false,
        y_title: "Users",
        y_title_text_direction: :bt,
        stagger_x_labels: false,
        x_label_format: "%Y-%m",
        y_label_format: "%Y-%m",
        min_x_value: FIRST_MONTH,
        timescale_divisions: TIMESCALE_DIVISIONS,
        add_popups: true,
        popup_format: "%Y-%m",
        area_fill: false,
        min_y_value: 0,
        number_format: "%d",
        show_lines: false
      }
      graph = TimeSeries.new(defaults.merge(opts))
      graph.add_data(
        data: yield,
        template: "%Y-%m"
      )
      graph.burn_svg_only
    }
  end
end
