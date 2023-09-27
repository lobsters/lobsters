# typed: false

class TimeSeries < SVG::Graph::TimeSeries
  include ActionView::Helpers::NumberHelper

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
end
