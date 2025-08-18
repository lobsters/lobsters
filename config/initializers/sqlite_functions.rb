ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.class_eval do
    alias_method :orig_initialize, :initialize

    def initialize(connection, logger = nil, pool = nil)
      orig_initialize(connection, logger, pool)

      raw_connection.create_function("regexp", 2) do |fn, pattern, expr|
        matcher = Regexp.new(pattern.to_s, Regexp::IGNORECASE)
        fn.result = expr.to_s.match(matcher) ? 1 : 0
      end

      raw_connection.create_function("if", 3) do |fn, c, t, f|
        fn.result = c == 1 ? t : f
      end

      raw_connection.create_aggregate("stddev", 1) do
        step do |fn, value|
          next if value.nil?

          fn[:n] ||= 0
          fn[:sum_of_squares] ||= 0
          fn[:sum] ||= 0

          fn[:n] += 1
          fn[:sum_of_squares] += value ** 2
          fn[:sum] += value
        end

        finalize do |fn|
          if fn[:n].nil?
            fn.result = nil
          else
            fn.result = Math.sqrt((fn[:sum_of_squares].to_f / fn[:n]) - ((fn[:sum].to_f / fn[:n]) ** 2))
          end
        end
      end
    end
  end
end
