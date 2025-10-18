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

  # Override to add a custom CSS class to the SVG element, for graphs
  # that should omit an extrapolated value for the current month.
  def burn_svg_only(add_no_extrapolation_css_class: false)
    svg = super()

    if add_no_extrapolation_css_class
      svg.sub!("<svg", "<svg class='no-extrapolation'")
    end

    svg
  end
end
