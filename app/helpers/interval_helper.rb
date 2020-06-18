module IntervalHelper
  TIME_INTERVALS = { "d" => "Day", "w" => "Week", "m" => "Month", "y" => "Year" }.freeze

  def time_interval(param)
    if (m = param.to_s.match(/\A(\d+)([#{TIME_INTERVALS.keys.join}])\z/))
      dur = m[1].to_i
      {
        param: param,
        dur: dur,
        intv: TIME_INTERVALS[m[2]],
        human: "#{dur == 1 ? '' : dur} #{TIME_INTERVALS[m[2]]}".downcase.pluralize(dur).chomp,
      }
    else
      { input: '1w', dur: 1, intv: "Week", human: 'week' }
    end
  end
end
