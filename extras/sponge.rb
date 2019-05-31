require "uri"
require "net/https"
require "resolv"
require "ipaddr"

class BadIPsError < StandardError; end
class DNSError < StandardError; end
class NoIPsError < StandardError; end

module Net
  class HTTP
    attr_accessor :address, :custom_conn_address, :skip_close

    def start # :yield: http
      if block_given? && !skip_close
        begin
          do_start
          return yield(self)
        ensure
          do_finish
        end
      end
      do_start
      self
    end

  private

    def conn_address
      if self.custom_conn_address.to_s != ""
        self.custom_conn_address
      else
        address
      end
    end
  end
end

class Sponge
  MAX_TIME = 60
  MAX_DNS_TIME = 5

  attr_accessor :debug, :last_res, :timeout

  # rfc3330
  BAD_NETS = [
    "0.0.0.0/8",
    "10.0.0.0/8",
    "127.0.0.0/8",
    "169.254.0.0/16",
    "172.16.0.0/12",
    "192.0.2.0/24",
    "192.88.99.0/24",
    "192.168.0.0/16",
    "198.18.0.0/15",
    "224.0.0.0/4",
    "240.0.0.0/4",
  ].freeze

  # old api
  def self.fetch(url, headers = {}, limit = 10)
    s = Sponge.new
    s.fetch(url, "get", nil, nil, headers, limit)
  end

  def initialize
    @cookies = {}
    @timeout = MAX_TIME
  end

  def set_cookie(host, name, val)
    dputs "setting cookie #{name} on domain #{host} to #{val}"

    if !@cookies[host]
      @cookies[host] = {}
    end

    if val.to_s == ""
      @cookies[host][name] ? @cookies[host][name].delete : nil
    else
      @cookies[host][name] = val
    end
  end

  def cookies(host)
    cooks = @cookies[host] || {}

    # check for domain cookies
    @cookies.keys.each do |dom|
      if dom.length < host.length && dom == host[host.length - dom.length .. host.length - 1]
        dputs "adding domain keys from #{dom}"
        cooks = cooks.merge @cookies[dom]
      end
    end

    if cooks
      return cooks.map {|k, v| "#{k}=#{v};" }.join(" ")
    else
      return ""
    end
  end

  def fetch(url, method = :get, fields = nil, raw_post_data = nil, headers = {}, limit = 10)
    raise ArgumentError.new("http redirection too deep") if limit <= 0

    uri = URI.parse(url)

    # we'll manually resolve the ip so we can verify it's not local
    ip = nil
    tip = nil
    ips = []
    retried = false
    begin
      Timeout.timeout(MAX_DNS_TIME) do
        ips = Resolv.getaddresses(uri.host)

        if !ips.any?
          raise NoIPsError
        end

        # reject ipv6 addresses
        ips.reject! {|address| address.match(/:/) }

        # pick a random one
        tip = ips[rand(ips.length)]
        ip = IPAddr.new(tip)
      end
    rescue Timeout::Error => e
      if retried
        raise DNSError.new("couldn't resolve #{uri.host} (DNS timeout)")
      else
        retried = true
        retry
      end
    rescue => e
      raise DNSError.new("couldn't resolve #{uri.host} (#{e.inspect})")
    end

    if !ip
      raise DNSError.new("couldn't resolve #{uri.host}")
    end

    if BAD_NETS.select {|n| IPAddr.new(n).include?(ip) }.any?
      # This blocks all requests to localhost, so you might need to comment
      # it out if you're building an end-to-end integration locally.
      raise BadIPsError.new("refusing to talk to IP #{ip}")
    end

    host = Net::HTTP.new(ip.to_s, uri.port)
    host.read_timeout = self.timeout
    if self.debug
      host.set_debug_output $stdout
    end

    if uri.scheme == "https"
      host.use_ssl = true
      host.address = uri.host
      host.custom_conn_address = ip.to_s
      host.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    send_headers = headers.dup

    path = (uri.path == "" ? "/" : uri.path)
    if uri.query
      path += "?" + uri.query
    elsif method == :get && raw_post_data
      path += "?" + URI.encode_www_form(raw_post_data)
      send_headers["Content-type"] = "application/x-www-form-urlencoded"
    end

    if method == :post
      if raw_post_data
        post_data = raw_post_data
        send_headers["Content-type"] = "application/x-www-form-urlencoded"
      else
        post_data = fields.map {|k, v| "#{k}=#{v}" }.join("&")
      end

      send_headers["Content-Length"] = post_data.length.to_s
    end

    path.gsub!(/^\/\//, "/")

    dputs "fetching #{url} (#{ip}) " +
          (uri.user ? "with http auth " + uri.user + "/" + ("*" * uri.password.length) + " " : "") +
          "by #{method} with cookies #{cookies(uri.host)}"

    send_headers = {
      "Host" => uri.host,
      "Cookie" => cookies(uri.host),
      "Referer" => url.to_s,
      "User-Agent" => "Mozilla/5.0 (compatible)",
    }.merge(send_headers || {})

    if uri.user
      send_headers["Authorization"] = "Basic " +
                                      ["#{uri.user}:#{uri.password}"].pack('m').delete("\r\n")
    end

    res = nil
    begin
      Timeout.timeout(self.timeout) do
        if method == :post
          res = host.post(path, post_data, send_headers)
        else
          res = host.get(path, send_headers)
        end
      end
    rescue Timeout::Error
      dputs "timed out during #{method}"
      return nil
    end

    if res.get_fields("Set-Cookie")
      res.get_fields("Set-Cookie").each do |cook|
        if (p = Regexp.new(/^([^=]+)=([^;]*)/).match(cook))
          set_cookie(uri.host, p[1], p[2])
        else
          dputs "unable to match cookie line #{cook}"
        end
      end
    end

    case res
    when Net::HTTPSuccess
      return res
    when Net::HTTPRedirection
      # follow
      newuri = URI.parse(res["location"])
      if newuri.host
        dputs "following redirection to " + res["location"]
      else
        # relative path
        newuri.host = uri.host
        newuri.scheme = uri.scheme
        newuri.port = uri.port
        newuri.path = "/#{newuri.path}"

        dputs "following relative redirection to " + newuri.to_s
      end

      fetch(newuri.to_s, "get", nil, nil, headers, limit - 1)
    end
  end

  def get(url)
    fetch(url, "get")
  end

  def post(url, fields)
    fetch(url, "post", fields)
  end

private

  def dputs(string)
    if self.debug
      puts string
    end
  end
end
