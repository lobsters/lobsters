# frozen_string_literal: true

module EmailBlocklistHelper
  def email_on_blocklist?(email)
    /^#{email[1 + email.index("@")..]}$/.match? File.read(FetchEmailBlocklistJob::STORAGE_PATH)
  end
end
