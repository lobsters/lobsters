# typed: false

class MastodonApp < ApplicationRecord
  validates :name, :client_id, :client_secret, presence: true
end
