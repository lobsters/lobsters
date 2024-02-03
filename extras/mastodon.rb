# typed: false

class Mastodon
  def self.enabled?
    true # Rails.env.production?
  end
end
