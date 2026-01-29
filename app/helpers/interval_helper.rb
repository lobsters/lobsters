# typed: false

module IntervalHelper
  PLACEHOLDER = {param: "1w", dur: 7, intv: "Day", human: "Week", placeholder: true}
  TIME_INTERVALS = {"h" => "Hour",
                    "d" => "Day",
                    "w" => "Week",
                    "m" => "Month",
                    "y" => "Year"}.freeze

  # security: must restrict user input to valid values
  def time_interval(param)
    if (m = param.to_s.match(/\A(\d+)([#{TIME_INTERVALS.keys.join}])\z/))
      dur = m[1].to_i
      return PLACEHOLDER unless dur > 0
      return PLACEHOLDER unless TIME_INTERVALS.include? m[2]
      intv = TIME_INTERVALS[m[2]]

      sqlite_dur, sqlite_intv =
        if intv == "Week"
          [dur * 7, "Day"]
        else
          [dur, intv]
        end

      {
        # recreate param with parsed values to prevent passing malicious user input
        param: "#{dur}#{m[2]}",
        dur: sqlite_dur,
        intv: sqlite_intv,
        human: "#{dur unless dur == 1} #{intv}".pluralize(dur).strip,
        placeholder: false
      }
    else
      PLACEHOLDER
    end
  end
end
