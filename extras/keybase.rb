class Keybase
  cattr_accessor :DOMAIN
  cattr_accessor :BASE_URL

  # these need to be overridden in config/initializers/production.rb
  @@DOMAIN = nil
  @@BASE_URL = nil

  def self.enabled?
    @@DOMAIN.present? || ENV['KEYBASE_BASE_URL']
  end

  def self.avatar_url(kb_username)
    s = Sponge.new
    url = [
      File.join(base_url, '/_/api/1.0/user/pic_url.json?'),
      "username=#{kb_username}",
    ].join('')
    res = s.fetch(url, :get).body
    return JSON.parse(res).fetch('pic_url', default_keybase_avatar_url)
  rescue ::DNSError, ::JSON::ParserError
    default_keybase_avatar_url
  end

  def self.proof_valid?(kb_username, kb_signature, username)
    s = Sponge.new
    url = [
      File.join(base_url, '/_/api/1.0/sig/proof_valid.json?'),
      "domain=#{@@DOMAIN}&",
      "kb_username=#{kb_username}&",
      "sig_hash=#{kb_signature}&",
      "username=#{username}",
    ].join('')
    res = s.fetch(url, :get).body
    js = JSON.parse(res)
    return js && js["proof_valid"].present? && js["proof_valid"]
  end

  def self.success_url(kb_username, kb_signature, kb_ua, username)
    File.join(base_url, "/_/proof_creation_success?domain=#{@@DOMAIN}&" \
      "kb_username=#{kb_username}&username=#{username}&" \
      "sig_hash=#{kb_signature}&kb_ua=#{kb_ua}")
  end

  def self.default_keybase_avatar_url
    "https://keybase.io/images/icons/icon-keybase-logo-48@2x.png"
  end

  def self.base_url
    @@BASE_URL || "https://keybase.io"
  end
end
