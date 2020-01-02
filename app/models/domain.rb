class Domain < ApplicationRecord
  has_many :stories # rubocop:disable Rails/HasManyOrHasOneDependent

  validates :domain, presence: true
end
