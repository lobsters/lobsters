class CreateStoryCardJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(story) { story.short_id }, duration: 5.minutes

  CACHE_DIR = Rails.public_path.join("story_image/").to_s.freeze

  def perform(story)
    return if story.url.blank?

    card_image_url = find_card_image_url(story.url)
    return if card_image_url.blank?

    story_card_image = generated_card_image(card_image_url)

    if story_card_image.present?
      FileUtils.mkdir_p(CACHE_DIR)

      File.open("#{CACHE_DIR}/.#{File.basename(story.short_id)}.png", "wb+") do |f|
        f.write story_card_image
      end

      File.rename("#{CACHE_DIR}/.#{File.basename(story.short_id)}.png", "#{CACHE_DIR}/#{File.basename(story.short_id)}.png")
    end
  end

  private

  def find_card_image_url(url)
    response = fetch_url(url)
    return nil unless response

    # If it's a PDF or too large, skip
    return nil if response.body.length >= 5.megabytes
    return nil if response["content-type"].to_s.match?(/pdf/)

    converted = response.body.force_encoding("utf-8")
    parsed = Nokogiri::HTML(converted.to_s)

    # Try <meta property="og:image">
    card_image_url = parsed.at_css("meta[property='og:image']")&.attributes&.[]("content")&.text

    # Then try <meta name="image">
    if card_image_url.blank?
      card_image_url = parsed.at_css("meta[name='image']")&.attributes&.[]("content")&.text
    end

    card_image_url
  rescue => e
    Rails.logger.error "Error finding image URL for story: #{e.message}"
    nil
  end

  def generated_card_image(url)
    res = fetch_url(url)
    return nil if res.blank?

    # Limit the image size according to Meta developer docs
    # https://developers.facebook.com/docs/sharing/webmasters/images/
    return nil if res.body.length >= 8.megabytes

    add_logo(res.body)
  rescue => e
    Rails.logger.error "Error generating story image: #{e.message}"
    nil
  end

  def add_logo(image_data)
    lobsters_logo = Vips::Image.new_from_file(Rails.public_path.join("touch-icon-144.png").to_s)
    image = Vips::Image.new_from_buffer(image_data, "")

    # since the lobsters icon image is a RGB, we need to ensure the image is RGB as well.
    image = image.flatten(background: [255, 255, 255]) if image.bands > 3

    # Resize lobsters_logo if it's too big compared to the image
    if lobsters_logo.height > image.height / 5
      lobsters_logo = lobsters_logo.resize((image.height / 5.0) / lobsters_logo.height)
    end

    combined_image = image.insert(lobsters_logo, 0, image.height - lobsters_logo.height)
    combined_image.write_to_buffer(".png")
  rescue Vips::Error => e
    Rails.logger.error "Vips error while generating image: #{e.message}"
    nil
  end

  def fetch_url(url)
    s = Sponge.new
    s.timeout = 3
    # User submitted URLs may have an incorrect https certificate, but we
    # don't want to fail the retrieval for this. Security risk is minimal.
    s.ssl_verify = false
    headers = {
      "User-agent" => "#{Rails.application.domain} for job",
      "Referer" => Rails.application.domain
    }
    s.fetch(url, :get, nil, nil, headers, 3)
  end
end
