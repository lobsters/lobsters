class Keybase
  cattr_accessor :DOMAIN
  cattr_accessor :BASE_URL

  # these need to be overridden in config/initializers/production.rb
  @@DOMAIN = nil
  @@BASE_URL = nil

  def self.enabled?
    @@DOMAIN.present?
  end

  def self.validate_initial(kb_username, kb_signature, username)
    s = Sponge.new
    url = [
      "#{@@BASE_URL}/_/api/1.0/sig/proof_valid.json?",
      "domain=#{@@DOMAIN}&",
      "kb_username=#{kb_username}&",
      "sig_hash=#{kb_signature}&",
      "username=#{username}",
    ].join('')
    res = s.fetch(url, :get).body
    js = JSON.parse(res)
    return js && js["proof_valid"].present? && js["proof_valid"]
  end

  def self.validate(kb_username, kb_signature, username)
    s = Sponge.new
    url = [
      "#{@@BASE_URL}/_/api/1.0/sig/proof_live.json?",
      "domain=#{@@DOMAIN}&",
      "kb_username=#{kb_username}&",
      "sig_hash=#{kb_signature}&",
      "username=#{username}",
    ].join('')
    res = s.fetch(url, :get).body
    js = JSON.parse(res)
    return js && js["proof_live"].present? && js["proof_live"]
  end

  def self.success_url(kb_username, kb_signature, kb_ua, username)
    return "#{@@BASE_URL}/_/proof_creation_success?domain=#{@@DOMAIN}&kb_username=#{kb_username}&username=#{username}&sig_hash=#{kb_signature}&kb_ua=#{kb_ua}"
  end
end
