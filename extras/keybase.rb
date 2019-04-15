class Keybase
  cattr_accessor :DOMAIN

  # these need to be overridden in config/initializers/production.rb
  @@DOMAIN = nil

  def self.enabled?
    self.DOMAIN.present?
  end

  def validate_initial(kb_username, kb_signature, username)
    s = Sponge.new
    res = s.fetch(
      "https://keybase.io/_/api/1.0/sig/proof_valid.json",
      :get,
      :domain => self.DOMAIN,
      :kb_username => kb_username,
      :sig_hash => kb_signature,
      :username => username,
    ).body
    js = JSON.parse(res)
    return js && js["proof_valid"].present? && js["proof_valid"]
  end

  def validate(kb_username, kb_signature, username)
    s = Sponge.new
    res = s.fetch(
      "https://keybase.io/_/api/1.0/sig/proof_live.json",
      :get,
      :domain => self.DOMAIN,
      :kb_username => kb_username,
      :sig_hash => kb_signature,
      :username => username,
    ).body
    js = JSON.parse(res)
    return js && js["proof_live"].present? && js["proof_live"]
  end

  def success_url(kb_username, kb_signature, kb_ua, username)
    return "https://keybase.io/_/proof_creation_success?domain=#{self.DOMAIN}&kb_username=#{kb_username}&username=#{username}&sig_hash=#{kb_signature}&kb_ua=#{kb_ua}"
  end
end
