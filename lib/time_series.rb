# typed: false

class TimeSeries < SVG::Graph::TimeSeries
  include ActionView::Helpers::NumberHelper

  # Whether to add an extrapolated end-of-month data point for the current month.
  # Provided as part of the options hash to the constructor.
  attr_accessor :extrapolate

  # these two methods are a patch on the gem's lack of time zone awareness
  def format x, y, description
    [
      Time.at(x).utc.strftime(popup_format),
      number_with_delimiter(y),
      description
    ].compact.join(", ")
  end

  def get_x_labels
    get_x_values.collect { |v| Time.at(v).utc.strftime(x_label_format) }
  end

  # improves y axis labels with commas
  def get_y_labels
    get_y_values.collect { |v| number_with_delimiter(v.to_i) }
  end

  # Override to add an extrapolated value for the current month, if
  # {extrapolate: true} has been passed into the constructor.
  def add_data(data:, template:)
    if extrapolate
      data = data_with_extrapolated_month(data)
    end

    super
  end

  private

  # Override to add a custom CSS class to the SVG element, if
  # {extrapolate: true} has been passed into the constructor, so that the extra
  # data point representing the extrapolated value can be styled differently.
  def start_svg
    super

    if extrapolate
      @root.attributes["class"] = (
        (@root.attributes["class"] || "") + " extrapolate"
      ).strip
    end
  end

  # Adds a second data point at the current month, representing the end-of-month
  # value, linearly extrapolated from the actual value of the current month so far.
  def data_with_extrapolated_month(data)
    current_month = data[-2]
    current_month_extrapolated_value = (
      data.last / (
        Time.now.utc.day.to_f /
        Time.days_in_month(Time.now.utc.month, Time.now.utc.year)
      )
    ).round

    [*data, current_month, current_month_extrapolated_value]
  end
end
