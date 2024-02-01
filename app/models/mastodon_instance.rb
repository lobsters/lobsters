# typed: false

class MastodonInstance < ApplicationRecord
  validates :name, :client_id, :client_secret, presence: true
end
