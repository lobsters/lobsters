class SqlHelpers
  def self.is_pg?
    ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
  end

  def self.interval(duration, unit)
    if is_pg?
      "interval '#{duration} #{unit}'"
    else
      "interval #{duration} #{unit}"
    end
  end
end
