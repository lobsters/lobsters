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
    domain = email.split("@").last.to_s.downcase
    return false if domain.empty?

    File.read(FetchEmailBlocklistJob::STORAGE_PATH).each_line(chomp: true).include?(domain)
  rescue Errno::ENOENT
    false
  end

  module_function :email_on_blocklist?
end
