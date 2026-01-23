# typed: false

class Stats
  FIRST_MONTH = Time.new(2012, 7, 3).utc.freeze
  TIMESCALE_DIVISIONS = "1 year".freeze

  def self.fill_users_graph_cache
    cache_monthly_graph(:users, {
      graph_title: "Users joining by month",
      scale_y_divisions: 100
    }) {
      User.pluck(:created_at).map { |created_at| created_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  def self.fill_active_users_graph_cache
    cache_monthly_graph(:active_users, {
      graph_title: "Active users by month",
      scale_y_divisions: 500,
      extrapolate: false
    }) {
      stories = Story.pluck(:created_at, :user_id).map { |created_at, user_id| [created_at.strftime("%Y-%m"), user_id] }
      votes = Vote.pluck(:updated_at, :user_id).map { |updated_at, user_id| [updated_at.strftime("%Y-%m"), user_id] }
      comments = Comment.pluck(:created_at, :user_id).map { |created_at, user_id| [created_at.strftime("%Y-%m"), user_id] }
      combined = (stories + votes + comments).group_by(&:first).transform_values { |record| record.map(&:last).uniq.count }
      combined.sort.flatten
    }
  end

  def self.fill_stories_graph_cache
    cache_monthly_graph(:stories, {
      graph_title: "Stories submitted by month",
      scale_y_divisions: 250
    }) {
      Story.pluck(:created_at).map { |created_at| created_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  def self.fill_comments_graph_cache
    cache_monthly_graph(:comments, {
      graph_title: "Comments posted by month",
      scale_y_divisions: 1_000
    }) {
      Comment.pluck(:created_at).map { |created_at| created_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  def self.fill_votes_graph_cache
    cache_monthly_graph(:votes, {
      graph_title: "Votes cast by month",
      scale_y_divisions: 10_000
    }) {
      Vote.pluck(:updated_at).map { |updated_at| updated_at.strftime("%Y-%m") }.tally.sort.flatten
    }
  end

  def self.cache_key(name)
    "stats_graphs/#{name}"
  end

  def self.get_cached_graph(name)
    Rails.cache.read(cache_key(name)) || "<i>No data</i>"
  end

  DEFAULTS = {
    width: 800,
    height: 300,
    graph_title: "Graph",
    show_graph_title: false,
    extrapolate: true,
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

  def self.cache_monthly_graph(name, opts)
    graph = TimeSeries.new(DEFAULTS.merge(opts))
    graph.add_data(
      data: yield,
      template: "%Y-%m"
    )
    svg = graph.burn_svg_only

    Rails.cache.write(cache_key(name), svg, expires_in: 2.days)
  end
end
