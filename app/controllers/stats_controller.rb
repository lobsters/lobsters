class StatsController < ApplicationController
  FIRST_MONTH = Time.new(2012, 7, 3).utc.freeze
  TIMESCALE_DIVISIONS = "1 year".freeze

  def index
    @title = "Stats"

    @users_graph = monthly_graph("users_graph", {
      :graph_title => "Users joining by month",
      :scale_y_divisions => 50,
    }) {
      User.group("date_format(created_at, '%Y-%m')")
    }

    @stories_graph = monthly_graph("stories_graph", {
      :graph_title => "Stories submitted by month",
      :scale_y_divisions => 100,
    }) {
      Story.group("date_format(created_at, '%Y-%m')")
    }

    @comments_graph = monthly_graph("comments_graph", {
      :graph_title => "Comments posted by month",
      :scale_y_divisions => 1_000,
    }) {
      Comment.group("date_format(created_at, '%Y-%m')")
    }

    @votes_graph = monthly_graph("votes_graph", {
      :graph_title => "Votes cast by month",
      :scale_y_divisions => 10_000,
    }) {
      Vote.group("date_format(updated_at, '%Y-%m')")
    }
  end

private

  def monthly_graph(cache_key, opts)
    Rails.cache.fetch(cache_key, expires_in: 1.day) {
      defaults = {
        :width => 800,
        :height => 300,
        :graph_title => "Graph",
        :show_graph_title => false,
        :no_css => false,
        :key => false,
        :scale_x_integers => true,
        :scale_y_integers => false,
        :show_data_values => false,
        :show_x_guidelines => false,
        :show_x_title => false,
        :x_title => "Time",
        :show_y_title => false,
        :y_title => "Users",
        :y_title_text_direction => :bt,
        :stagger_x_labels => false,
        :x_label_format => "%Y-%m",
        :y_label_format => "%Y-%m",
        :min_x_value => FIRST_MONTH,
        :timescale_divisions => TIMESCALE_DIVISIONS,
        :add_popups => true,
        :popup_format => "%Y-%m",
        :area_fill => false,
        :min_y_value => 0,
        :number_format => "%d",
        :show_lines => false,
      }
      graph = TimeSeries.new(defaults.merge(opts))
      graph.add_data(
        data: yield.count.to_a.flatten,
        template: "%Y-%m",
      )
      graph.burn_svg_only
    }
  end
end
