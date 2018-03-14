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

class String
  def forcibly_convert_to_utf8
    begin
      if self.encoding.to_s == "UTF-8" && self.valid_encoding?
        return self
      end

      str = self.dup.force_encoding("binary").encode(
        "utf-8",
        :invalid => :replace,
        :undef => :replace,
        :replace => "?"
      )

      if !str.valid_encoding? || str.encoding.to_s != "UTF-8"
        raise Encoding::UndefinedConversionError
      end

    rescue Encoding::UndefinedConversionError
      str = self.chars.map {|c|
        begin
          c.encode("UTF-8", :invalid => :replace, :undef => :replace)
        rescue
          "?".encode("UTF-8")
        end
      }.join

      if !str.valid_encoding?
        raise "still bogus encoding"
      end
    end

    str
  end
end
