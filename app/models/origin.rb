# typed: false

class Origin < ApplicationRecord
  belongs_to :domain, optional: false

  validates :identifier, presence: true, length: {maximum: 255}
end
