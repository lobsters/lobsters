# frozen_string_literal: true

class FetchEmailBlocklistJob < ApplicationJob
  queue_as :default

  MEDIA_TYPE = "application/vnd.github.raw+json"
  BLOCKLIST_URL = "https://api.github.com/repos/disposable-email-domains/disposable-email-domains/contents/disposable_email_blocklist.conf"
  STORAGE_PATH = Rails.root.join("storage/disposable_email_blocklist.conf")

  def perform
    response = request_blocklist

    if response.nil? || response.body.nil?
      Rails.logger.error "Failed to fetch email blocklist from #{BLOCKLIST_URL}"
      return
    end

    email_blocklist_content = decode_response(response)
    write_blocklist(email_blocklist_content)
  end

  private

  def request_blocklist
    s = Sponge.new
    s.fetch(
      BLOCKLIST_URL,
      :get,
      nil,
      {"Accept" => MEDIA_TYPE}
    )
  end

  # File is returned encoded via Base64
  # This method decodes the Base64-encoded content
  def decode_response(response)
    blocklist = JSON.parse(response.body)

    return unless valid_response?(blocklist)

    Base64.decode64(blocklist["content"])
  end

  def valid_response?(blocklist)
    return false if blocklist["content"].blank?
    return false unless blocklist["encoding"] == "base64"
    return false unless blocklist["type"] == "file"

    true
  end

  def write_blocklist(email_blocklist_content)
    unless Dir.exist?("storage")
      Dir.mkdir("storage")
    end
    File.write(STORAGE_PATH, email_blocklist_content)
  end
end
