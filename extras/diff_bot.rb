# typed: false

class DiffBot
  # see README.md on setting up credentials

  DIFFBOT_API_URL = "http://www.diffbot.com/api/article".freeze

  def self.get_story_text(story)
    if !Rails.application.credentials.diffbot.api_key
      return
    end

    return "" if story.url.nil?

    # XXX: diffbot tries to read pdfs as text, so disable for now
    if /\.pdf$/i.match?(story.url.to_s)
      return nil
    end

    db_url = "#{DIFFBOT_API_URL}?token=#{Rails.application.credentials.diffbot.api_key}&url=#{CGI.escape(story.url)}"

    begin
      s = Sponge.new
      # we're not doing this interactively, so take a while
      s.timeout = 45
      res = s.fetch(db_url).body
      if res.present?
        j = JSON.parse(res)

        # turn newlines into double newlines, so they become paragraphs
        j["text"] = j["text"].to_s.gsub("\n", "\n\n")

        while j["text"].include?("\n\n\n")
          j["text"].gsub!("\n\n\n", "\n\n")
        end

        return j["text"]
      end
    rescue => e
      Rails.logger.error "error fetching #{db_url} #{e.backtrace.first} #{e.message}"
    end

    begin
      s = Sponge.new
      s.timeout = 45
      s.fetch(story.archiveorg_url)
    rescue => e
      Rails.logger.error "error caching #{db_url}: #{e.backtrace.first} #{e.message}"
    end

    nil
  end
end
