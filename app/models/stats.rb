# typed: false

class Stats
  FIRST_MONTH = Time.new(2012, 7, 3).utc.freeze
  TIMESCALE_DIVISIONS = "1 year".freeze

  def self.get_users_graph(read_only)
    monthly_graph("users_graph", {
      graph_title: "Users joining by month",
      scale_y_divisions: 100,
      read_only: read_only
    }) {
      User.pluck(:created_at).map { |created_at| created_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  def self.get_active_users_graph(read_only)
    monthly_graph("active_users_graph", {
      graph_title: "Active users by month",
      scale_y_divisions: 500,
      read_only: read_only
    }) {
      stories = Story.pluck(:created_at, :user_id).map { |created_at, user_id| [created_at.strftime("%Y-%m"), user_id] }
      votes = Vote.pluck(:updated_at, :user_id).map { |updated_at, user_id| [updated_at.strftime("%Y-%m"), user_id] }
      comments = Comment.pluck(:created_at, :user_id).map { |created_at, user_id| [created_at.strftime("%Y-%m"), user_id] }
      combined = (stories + votes + comments).group_by(&:first).transform_values { |record| record.map(&:last).uniq.count }
      combined.sort.flatten
    }
  end

  def self.get_stories_graph(read_only)
    monthly_graph("stories_graph", {
      graph_title: "Stories submitted by month",
      scale_y_divisions: 250,
      read_only: read_only
    }) {
      Story.pluck(:created_at).map { |created_at| created_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  def self.get_comments_graph(read_only)
    monthly_graph("comments_graph", {
      graph_title: "Comments posted by month",
      scale_y_divisions: 1_000,
      read_only: read_only
    }) {
      Comment.pluck(:created_at).map { |created_at| created_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  def self.get_votes_graph(read_only)
    monthly_graph("votes_graph", {
      graph_title: "Votes cast by month",
      scale_y_divisions: 10_000,
      read_only: read_only
    }) {
      Vote.pluck(:updated_at).map { |updated_at| updated_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  DEFAULTS = {
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

  def self.monthly_graph(cache_key, opts)
    if opts[:read_only]
      cached_data = Rails.cache.read(cache_key)
      return cached_data || "<i>No data</i>"
    end

    graph = TimeSeries.new(DEFAULTS.merge(opts))
    graph.add_data(
      data: yield,
      template: "%Y-%m"
    )
    svg = graph.burn_svg_only

    Rails.cache.write(cache_key, svg, expires_in: 2.days)
  end
end
