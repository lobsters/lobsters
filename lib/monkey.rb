module ActiveRecord
  class Base
    def self.q(str)
      ActiveRecord::Base.connection.quote(str)
    end

    def q(str)
      ActiveRecord::Base.connection.quote(str)
    end
  end
end

# XXX stupid hack to strip out utf8mb4 chars that may break mysql queries
# TODO upgrade to mysql 5.5, convert tables to utf8mb4, upgrade mysql2 gem when
# it supports utf8mb4, and remove this hack
class String
  def remove_mb4
    t = "".force_encoding(self.encoding)

    self.each_char do |c|
      if c.bytesize == 4
        t << " "
      else
        t << c
      end
    end

    t
  end
end
