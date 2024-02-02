# typed: false

class Mastodon
  def self.enabled?
    Rails.env.production?
  end
end
