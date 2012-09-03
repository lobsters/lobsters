require "socket"

class Countinual
  cattr_accessor :API_KEY

  # this needs to be overridden in config/initializers/production.rb
  @@API_KEY = nil

  COUNTINUAL_HOST = "207.158.15.115"
  COUNTINUAL_PORT = 1025

  def self.count!(counter, value, time = nil)
    if !@@API_KEY
      return
    end

    if time
      time = time.to_i
    else
      time = Time.now.to_i
    end

    line = "#{@@API_KEY} #{counter} #{value} #{time}\n"

    begin
      sock = UDPSocket.open
      sock.send(line, 0, COUNTINUAL_HOST, COUNTINUAL_PORT)
    rescue => e
      Rails.logger.info "Countinual error: #{e.message} (#{line.inspect})"
    ensure
      sock.close
    end
  end
end
