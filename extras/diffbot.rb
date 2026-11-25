class Diffbot
  # see README.md on setting up credentials

  DIFFBOT_API_URL = "http://api.diffbot.com/v3/article".freeze
  TIMEOUT = 45

  def self.get_story_text(url)
    if !Rails.application.credentials.diffbot&.api_key || Rails.env.test?
      return
    end

    return "" if url.nil?

    text = try_fetch_diffbot(url)
    text = try_fetch_diffbot("https://web.archive.org/web/3/#{CGI.escape(url)}") if text.blank?

    text
  end

  # https://www.diffbot.com/docs/extract/article
  def self.try_fetch_diffbot(url)
    db_url = "#{DIFFBOT_API_URL}?token=#{Rails.application.credentials.diffbot.api_key}&url=#{CGI.escape(url)}"

    s = Sponge.new
    s.timeout = TIMEOUT
    resp = s.try_fetch(db_url)
    return if resp&.body.blank?
    body = resp.body.force_encoding("UTF-8")
    data = JSON.parse(body)

    return if data["errorCode"] == 500

    # > At the moment, only a single object will be returned for Article API requests.
    text = data["objects"][0]["text"]

    # turn newlines into double newlines, so they become paragraphs
    text = text.to_s.gsub("\n", "\n\n")

    while text.include?("\n\n\n")
      text.gsub!("\n\n\n", "\n\n")
    end

    text
  end
end
