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
