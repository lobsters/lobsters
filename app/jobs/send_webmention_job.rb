class SendWebmentionJob < ApplicationJob
  queue_as :default

  def endpoint_from_body(html)
    doc = Nokogiri::HTML(html)

    if !doc.css('[rel~="webmention"]').css("[href]").empty?
      doc.css('[rel~="webmention"]').css("[href]").attribute("href").value
    elsif !doc.css('[rel="http://webmention.org/"]').css("[href]").empty?
      doc.css('[rel="http://webmention.org/"]').css("[href]").attribute("href").value
    elsif !doc.css('[rel="http://webmention.org"]').css("[href]").empty?
      doc.css('[rel="http://webmention.org"]').css("[href]").attribute("href").value
    end
  end

  def endpoint_from_headers(header)
    return unless header

    if (matches = header.match(/<([^>]+)>; rel="[^"]*\s?webmention\s?[^"]*"/))
      matches[1]
    elsif (matches = header.match(/<([^>]+)>; rel=webmention/))
      matches[1]
    elsif (matches = header.match(/rel="[^"]*\s?webmention\s?[^"]*"; <([^>]+)>/))
      matches[1]
    elsif (matches = header.match(/rel=webmention; <([^>]+)>/))
      matches[1]
    elsif (matches = header.match(/<([^>]+)>; rel="http:\/\/webmention\.org\/?"/))
      matches[1]
    elsif (matches = header.match(/rel="http:\/\/webmention\.org\/?"; <([^>]+)>/))
      matches[1]
    end
  end

  # Some pages could return a relative link as their webmention endpoint.
  # We need to translate this relative link to an absolute one.
  def uri_to_absolute(uri, req_uri)
    abs_uri = URI.parse(uri)
    if abs_uri.host
      # Already absolute.
      uri
    else
      abs_uri.host = req_uri.host
      abs_uri.scheme = req_uri.scheme
      abs_uri.port = req_uri.port
      abs_uri
    end
  end

  def send_webmention(source, target, endpoint)
    sp = Sponge.new
    sp.timeout = 10
    # Don't check SSL certificate here for backward compatibility, security risk
    # is minimal.
    sp.ssl_verify = false
    sp.fetch(endpoint.to_s, :post, {
      "source" => URI.encode_www_form_component(source),
      "target" => URI.encode_www_form_component(target)
    }, nil, {}, 3)
  end

  def perform(story)
    # Could have been deleted between creation and now
    return if story.is_gone?
    # Need a URL to send the webmention to
    return if story.url.blank?
    # Don't try to send webmentions in dev
    return if Rails.env.development?

    sp = Sponge.new
    sp.timeout = 10
    begin
      response = sp.fetch(URI::RFC2396_PARSER.escape(story.url), :get, {}, nil, {
        "User-agent" => "#{Rails.application.domain} webmention endpoint lookup"
      }, 3)
    rescue BadIPsError, NoIPsError, DNSError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, TooManyRedirects, Zlib::DataError
      # other people's DNS/hosting issues (usually transient); just drop the webmention on the floor
      return
    end
    return unless response

    wm_endpoint_raw = endpoint_from_headers(response["link"]) ||
      endpoint_from_body(response.body.to_s)
    return unless wm_endpoint_raw

    wm_endpoint = uri_to_absolute(wm_endpoint_raw, URI.parse(story.url))
    send_webmention(Routes.story_short_id_url(story), story.url, wm_endpoint)
  end
end
