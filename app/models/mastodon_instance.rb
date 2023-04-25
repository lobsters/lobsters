class MastodonInstance < ApplicationRecord
  validates :name, :client_id, :client_secret, presence: true
end
