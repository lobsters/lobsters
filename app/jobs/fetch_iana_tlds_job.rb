# frozen_string_literal: true

class FetchIanaTldsJob < ApplicationJob
  queue_as :default

  LIST_URL = "https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
  STORAGE_PATH = Rails.root.join("storage/iana_tlds.conf")

  def perform
    response = Sponge.new.fetch(LIST_URL)

    if response.nil? || response.body.nil?
      Rails.logger.error "Failed to fetch IANA TLDs from #{LIST_URL}"
      return
    end

    iana_tlds_content = decode_response(response)
    write_iana_tlds(iana_tlds_content)
  end

  def self.tlds
    File.read(FetchIanaTldsJob::STORAGE_PATH).split(" ")
  rescue Errno::ENOENT
    []
  end

  private

  def decode_response(response)
    response.body
      .split
      .reject { it.start_with?("#") }
      .map { it.chomp.downcase }
      .join(" ")
  end

  def write_iana_tlds(iana_tlds_content)
    FileUtils.mkdir_p("storage") unless Rails.env.production?
    File.write(STORAGE_PATH, iana_tlds_content)
  end
end
