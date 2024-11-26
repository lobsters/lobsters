# typed: false

class Keybase
  # see README.md on setting up credentials

  def self.enabled?
    Rails.application.credentials.keybase.domain.present? || ENV["KEYBASE_BASE_URL"]
  end

  def self.avatar_url(kb_username)
    s = Sponge.new
    url = [
      File.join(base_url, "/_/api/1.0/user/pic_url.json?"),
      "username=#{kb_username}"
    ].join("")
    res = s.fetch(url, :get).body
    JSON.parse(res).fetch("pic_url", default_keybase_avatar_url)
  rescue ::DNSError, ::JSON::ParserError
    default_keybase_avatar_url
  end

  def self.proof_valid?(kb_username, kb_signature, username)
    s = Sponge.new
    url = [
      File.join(base_url, "/_/api/1.0/sig/proof_valid.json?"),
      "domain=#{Rails.application.credentials.keybase.domain}&",
      "kb_username=#{kb_username}&",
      "sig_hash=#{kb_signature}&",
      "username=#{username}"
    ].join("")
    res = s.fetch(url, :get).body
    js = JSON.parse(res)
    js && js["proof_valid"].present? && js["proof_valid"]
  end

  def self.success_url(kb_username, kb_signature, kb_ua, username)
    File.join(base_url, "/_/proof_creation_success?domain=#{Rails.application.credentials.keybase.domain}&" \
      "kb_username=#{kb_username}&username=#{username}&" \
      "sig_hash=#{kb_signature}&kb_ua=#{kb_ua}")
  end

  def self.default_keybase_avatar_url
    "https://keybase.io/images/icons/icon-keybase-logo-48@2x.png"
  end

  def self.base_url
    Rails.application.credentials.keybase.base_url
  end
end
