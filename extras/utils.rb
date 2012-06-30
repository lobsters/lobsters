class Utils
  def self.random_str(len)
    str = ""
    while str.length < len
      chr = OpenSSL::Random.random_bytes(1)
      ord = chr.unpack('C')[0]

      #          0            9              A            Z              a            z
      if (ord >= 48 && ord <= 57) || (ord >= 65 && ord <= 90) || (ord >= 97 && ord <= 122)
        str += chr
      end
    end

    return str
  end
end

class ActiveRecord::Base
  def self.q(str)
    ActiveRecord::Base.connection.quote(str)
  end

  def q(str)
    ActiveRecord::Base.connection.quote(str)
  end
end
