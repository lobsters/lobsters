# typed: false

require "uri"
require "net/https"
require "resolv"
require "ipaddr"

class BadIPsError < StandardError; end

class DNSError < StandardError; end

class NoIPsError < StandardError; end

class TooManyRedirects < StandardError; end

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
      if custom_conn_address.to_s != ""
        custom_conn_address
      else
        address
      end
    end
  end
end

class Sponge
  MAX_TIME = 60
  MAX_DNS_TIME = 5

  attr_accessor :debug, :last_res, :timeout, :ssl_verify

  # primarily sourced from rfc6890
  BAD_NETS = [
    "0.0.0.0/8",
    "10.0.0.0/8",
    "100.64.0.0/10",
    "127.0.0.0/8",
    "169.254.0.0/16",
    "172.16.0.0/12",
    "192.0.0.0/24",
    # "192.0.0.0/29", # mentioned in rfc6890 because of different attributes but is a subset of 192.0.0.0/24
    "192.0.2.0/24",
    # "192.88.99.0/24", # mentioned in rfc6890 but marked Global, 6to4 relay anycast
    "192.168.0.0/16",
    "198.18.0.0/15",
    "198.51.100.0/24",
    "203.0.113.0/24",
    "224.0.0.0/4", # mentioned in rfc5735 only, multicast addresses
    "240.0.0.0/4",
    "255.255.255.255/32"
  ].freeze

  # old api
  def self.fetch(url, headers = {}, limit = 10)
    s = Sponge.new
    s.ssl_verify = false # backward compatibility
    s.fetch(url, :get, {}, nil, headers, limit)
  end

  def initialize
    @cookies = {}
    @timeout = MAX_TIME
    @ssl_verify = OpenSSL::SSL::VERIFY_PEER
  end

  def set_cookie(host, name, val)
    dputs "setting cookie #{name} on domain #{host} to #{val}"

    if !@cookies[host]
      @cookies[host] = {}
    end

    if val.to_s == ""
      @cookies[host][name]&.delete
    else
      @cookies[host][name] = val
    end
  end

  def cookies(host)
    cooks = @cookies[host] || {}

    # check for domain cookies
    @cookies.each_key do |dom|
      if dom.length < host.length && dom == host[host.length - dom.length..host.length - 1]
        dputs "adding domain keys from #{dom}"
        cooks = cooks.merge @cookies[dom]
      end
    end

    if cooks
      cooks.map { |k, v| "#{k}=#{v};" }.join(" ")
    else
      ""
    end
  end

  def fetch(url, method = :get, fields = {}, raw_post_data = nil, headers = {}, limit = 10)
    raise TooManyRedirects.new("http redirection too deep") if limit <= 0

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
        ips.reject! { |address| address.match(/:/) }

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

    if BAD_NETS.select { |n| IPAddr.new(n).include?(ip) }.any?
      # This blocks all requests to localhost, so you might need to comment
      # it out if you're building an end-to-end integration locally.
      raise BadIPsError.new("refusing to talk to IP #{ip}")
    end

    host = Net::HTTP.new(ip.to_s, uri.port)
    host.read_timeout = timeout
    if debug
      host.set_debug_output $stdout
    end

    if uri.scheme == "https"
      host.use_ssl = true
      host.address = uri.host
      host.custom_conn_address = ip.to_s
      host.verify_mode = ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    end

    send_headers = headers.dup

    path = ((uri.path == "") ? "/" : uri.path)
    if uri.query
      path += "?" + uri.query
    elsif method == :get && raw_post_data
      path += "?" + URI.encode_www_form(raw_post_data)
      send_headers["Content-Type"] = "application/x-www-form-urlencoded"
    end

    if method != :get
      if raw_post_data
        post_data = raw_post_data
        send_headers["Content-Type"] ||= "application/x-www-form-urlencoded"
      else
        post_data = fields.to_query
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
      "User-Agent" => "Mozilla/5.0 (compatible) #{Rails.application.domain}"
    }.merge(send_headers || {})

    if uri.user
      send_headers["Authorization"] = "Basic " +
        ["#{uri.user}:#{uri.password}"].pack("m").delete("\r\n")
    end

    res = nil
    begin
      Timeout.timeout(timeout) do
        res = case method
        when :get
          host.get(path, send_headers)
        when :delete
          # The Net::HTTP#delete convenience method doesn't support sending a
          # body, which we need for certain API endpoints (for example, GitHub
          # token revocation).
          req = Net::HTTP::Delete.new(path, send_headers)
          req.body = post_data if post_data
          host.request(req)
        when :patch
          host.patch(path, send_headers)
        when :put
          host.put(path, send_headers)
        when :post
          host.post(path, post_data, send_headers)
        end
      end
    rescue Timeout::Error
      dputs "timed out during #{method}"
      return nil
    end

    res.get_fields("Set-Cookie")&.each do |cook|
      if (p = /^([^=]+)=([^;]*)/.match(cook))
        set_cookie(uri.host, p[1], p[2])
      else
        dputs "unable to match cookie line #{cook}"
      end
    end

    case res
    when Net::HTTPSuccess
      res
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

      fetch(newuri.to_s, :get, {}, nil, headers, limit - 1)
    end
  end

  def get(url)
    fetch(url, :get)
  end

  def post(url, fields)
    fetch(url, :post, fields)
  end

  private

  def dputs(string)
    if debug
      puts string
    end
  end
end
