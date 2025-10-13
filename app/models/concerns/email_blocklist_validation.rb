# frozen_string_literal: true

module EmailBlocklistValidation
  extend ActiveSupport::Concern

  included do
    validate :email_blocklist
  end

  def email_blocklist
    if email && email_on_blocklist?(email)
      errors.add(:email, "disposable emails are blocked")
    end
  end

  def email_on_blocklist?(email)
    /^#{email[1 + email.index("@")..]}$/.match? File.read(FetchEmailBlocklistJob::STORAGE_PATH)
  rescue Errno::ENOENT
    false
  end

  module_function :email_on_blocklist?
end
