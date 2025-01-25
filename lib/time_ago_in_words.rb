# typed: false

module TimeAgoInWords
  def how_long_ago(time)
    secs = (Time.current - time).to_i
    if secs <= 5
      "just now"
    elsif secs < 60
      "less than a minute ago"
    elsif secs < (60 * 60)
      mins = (secs / 60.0).floor
      "#{mins} #{"minute".pluralize(mins)} ago"
    elsif secs < (60 * 60 * 48)
      hours = (secs / 60.0 / 60.0).floor
      "#{hours} #{"hour".pluralize(hours)} ago"
    elsif secs < (60 * 60 * 24 * 30)
      days = (secs / 60.0 / 60.0 / 24.0).floor
      "#{days} #{"day".pluralize(days)} ago"
    elsif secs < (60 * 60 * 24 * 365)
      months = (secs / 60.0 / 60.0 / 24.0 / 30.0).floor
      "#{months} #{"month".pluralize(months)} ago"
    else
      years = (secs / 60.0 / 60.0 / 24.0 / 365.0).floor
      "#{years} #{"year".pluralize(years)} ago"
    end
  end
end
