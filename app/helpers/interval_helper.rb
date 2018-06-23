module IntervalHelper
  TIME_INTERVALS = { "d" => "Day", "w" => "Week", "m" => "Month", "y" => "Year" }.freeze

  def time_interval(param)
    if (m = param.to_s.match(/\A(\d+)([#{TIME_INTERVALS.keys.join}])\z/))
      { dur: m[1].to_i, intv: TIME_INTERVALS[m[2]] }
    else
      { dur: 1, intv: "Week" }
    end
  end
end
