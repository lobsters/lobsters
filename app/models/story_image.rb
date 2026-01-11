class StoryImage
  CACHE_DIR = Rails.public_path.join("story_image").freeze
  VALID_IMAGE_CONTENT_TYPES = %w[
    image/png
    image/jpeg
    image/jpg
    image/webp
    image/svg+xml
  ].freeze

  def initialize(short_id_or_story)
    @short_id = short_id_or_story.is_a?(Story) ? short_id_or_story.short_id : short_id_or_story
  end

  def path
    CACHE_DIR.join("#{File.basename(@short_id)}.png")
  end

  def exists?
    path.exist?
  end

  def generate(url)
    return if url.blank?

    card_image_url = find_card_image_url(url)
    return if card_image_url.blank?

    story_card_image = generated_card_image(card_image_url)

    if story_card_image.present?
      FileUtils.mkdir_p(CACHE_DIR)

      temp_filename = ".#{File.basename(@short_id)}.png"
      temp_path = CACHE_DIR.join(temp_filename)

      File.open(temp_path, "wb+") do |f|
        f.write story_card_image
      end

      File.rename(temp_path, path)
    end
  end

  private

  def find_card_image_url(url)
    response = fetch_url(url)
    return nil unless response

    # If it's too large, skip
    return nil if response.body.length >= 5.megabytes

    # Clean the content-type
    content_type = response["content-type"].to_s.downcase.split(";").first.strip

    # Check for a direct image url
    return url if VALID_IMAGE_CONTENT_TYPES.include?(content_type)

    return nil unless content_type == "text/html"

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
    headers = {
      "Referer" => Routes.story_short_id_url(@short_id)
    }
    s.fetch(url, :get, nil, nil, headers, 3)
  end
end
